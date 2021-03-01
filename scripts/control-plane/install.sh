#!/bin/sh

# Set VERSION to main if CNO_VERSION env variable is not set
# Ex: export CNO_VERSION="feature/mysql-operator"
[[ -z "${CNO_VERSION}" ]] && VERSION='main' || VERSION="${CNO_VERSION}"

# Set INGRESS to nginx if CNO_INGRESS env variable is not set
# Ex: export CNO_INGRESS="nginx"
[[ -z "${CNO_INGRESS}" ]] && INGRESS='nginx' || INGRESS="${CNO_INGRESS}"

hasKubectl() {
    hasKubectl=$(which kubectl)
    if [ "$?" = "1" ]; then
        echo "============================================================"
        echo "  CNO installation failed."
        echo "  You need kubectl to use this script."
        echo "============================================================"
        exit 1
    fi
}

hasSetDomainSuffix() {
    if [ -z $INGRESS_DOMAIN ]; then
        echo "============================================================"
        echo "  CNO installation failed."
        echo "  Provide your cluster ingress domain suffix by exporting env variable INGRESS_DOMAIN."
        echo "  Ex: $ export INGRESS_DOMAIN=cluster1.beopenit.com"
        echo "============================================================"
        exit 1
    fi
}

installCno() {
    # Create cno namespace
    kubectl create namespace cno-system

    # Install kafka operator
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/kafka-strimzi/crds/kafkaOperator.yaml
    kubectl -n cno-system rollout status deploy strimzi-cluster-operator

    # Deploy a kafka cluster
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/kafka.yaml | sed -e 's|INGRESS_DOMAIN|'"$INGRESS_DOMAIN"'|g' | kubectl -n cno-system apply -f -
    # waiting for zookeeper deployment
    waitForRessourceCreated pod cno-kafka-cluster-zookeeper-0
    kubectl -n cno-system wait -l statefulset.kubernetes.io/pod-name=cno-kafka-cluster-zookeeper-0 --for=condition=ready pod --timeout=5m
    # waiting for kafka deployment
    waitForRessourceCreated pod cno-kafka-cluster-kafka-0
    kubectl -n cno-system wait -l statefulset.kubernetes.io/pod-name=cno-kafka-cluster-kafka-0 --for=condition=ready pod --timeout=5m
    # Create cno kafka super-admin user
    kubectl -n cno-system  apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/cno-super-admin.yaml

    # Install keycloak Operator
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/crds/keycloak-all.yaml

    # Deploy keycloak Cluster and patch the ingress
    CLIENT_CNO_API=$(openssl rand -base64 14)
    kubectl -n cno-system create secret generic keycloak-client-cno-api  --from-literal=OIDC_CLIENT_SECRET="${CLIENT_CNO_API}"
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/cno-realm-configmap.yml | sed -e 's|cno-api-client-secret|'"$CLIENT_CNO_API"'|g' |kubectl -n cno-system apply -f  -
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/keycloak.yaml

    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/cno-realm.yml

    #If PSP issue
    waitForRessourceCreated deployment keycloak-postgresql
    if [ "${CNO_POD_POLICY_ACTIVITED}" = "true" ]; then
        kubectl -n cno-system patch deployment keycloak-postgresql --patch "$(curl --silent https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/patch-psp-postgresql.yaml)"
    fi
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/ingress/$INGRESS/keycloak-ingress.yaml
    kubectl -n cno-system patch ing/keycloak --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-auth.$INGRESS_DOMAIN'}]"


    # Deploy CNO operator
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/cno-operator/cno-operator-all.yaml

    # Create CNO service account, role and binding
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/templates/cno-rbac.yaml

    # Install Mysql Operator
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/mysql-operator/mysql-operator.yaml

    # Install Mysql cluster
    MYSQL_PWD=$(openssl rand -base64 14)
    kubectl -n cno-system create secret generic cno-api-db-secret  --from-literal=ROOT_PASSWORD="${MYSQL_PWD}"
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-api/cno-api-mysql.yaml
    waitForRessourceCreated pod cno-api-mysql-0
    kubectl -n cno-system wait -l statefulset.kubernetes.io/pod-name=cno-api-mysql-0 --for=condition=ready pod --timeout=5m
    sleep 10s
    kubectl -n cno-system exec -it cno-api-mysql-0 -- mysql -u root -p$MYSQL_PWD -e "create database cnoapi"

    # Create CNO configMap
    kubectl create cm -n cno-system cno-config --from-literal OIDC_SERVER_BASE_URL=https://cno-auth.$INGRESS_DOMAIN \
     --from-literal OIDC_REALM=cno-realm --from-literal KAFKA_BROKERS=kafka-cluster-kafka-external-bootstrap:9094 \
     --from-literal KAFKA_TLS_ENABLED="true"  --from-literal KAFKA_TOPIC_NOTIFICATION=cno-notification 

    # kafka auth config
    kubectl -n cno-system get secret/cno-kafka-cluster-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode > /tmp/cno-ca
    kubectl -n cno-system get secret/cno-kafka-superadmin -o jsonpath='{.data.user\.key}' | base64 --decode > /tmp/cno-kafka-key
    kubectl -n cno-system  get secret/cno-kafka-superadmin -o jsonpath='{.data.user\.crt}' | base64 --decode > /tmp/cno-kafka-cert
    kubectl  -n cno-system create secret generic kafkaconfig --from-literal=KAFKA_BROKERS=kafka-cluster-kafka-bootstrap --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key
    # Clean
    rm -rf /tmp/cno-*

    # Install CNO API
    DEFAULT_AGENT_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-api/cno-api.yaml |
        sed 's|$SERVER_URL|https://cno-api.'"$INGRESS_DOMAIN"'|g; s|$OIDC_SERVER_URL|https://cno-auth.'"$INGRESS_DOMAIN"'/auth/realms/cno/|g; s|$OIDC_SERVER_BASE_URL|https://cno-auth.'"$INGRESS_DOMAIN"'|g; s|$OIDC_REALM|cno|g; s|$OIDC_CLIENT_ID|cno-api|g; s|$KAFKA_BROKERS|cno-kafka-cluster-kafka-bootstrap:9093|g; s|$CREATE_DEFAULT_CLUSTER|"true"|g; s|$DEFAULT_CLUSTER_ID|'"$DEFAULT_AGENT_ID"'|g'
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-api/cno-api.yaml |
        sed 's|$SERVER_URL|https://cno-api.'"$INGRESS_DOMAIN"'|g; s|$OIDC_SERVER_URL|https://cno-auth.'"$INGRESS_DOMAIN"'/auth/realms/cno/|g; s|$OIDC_SERVER_BASE_URL|https://cno-auth.'"$INGRESS_DOMAIN"'|g; s|$OIDC_REALM|cno|g; s|$OIDC_CLIENT_ID|cno-api|g; s|$KAFKA_BROKERS|cno-kafka-cluster-kafka-bootstrap:9093|g; s|$CREATE_DEFAULT_CLUSTER|"true"|g; s|$DEFAULT_CLUSTER_ID|'"$DEFAULT_AGENT_ID"'|g' |
        kubectl -n cno-system apply -f -
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/ingress/$INGRESS/api-ingress.yaml
    kubectl -n cno-system patch ing/cno-api --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-api.$INGRESS_DOMAIN'}]"
    kubectl -n cno-system rollout status deploy cno-api
    # Install CNO NOTIFICATION
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/notification/cno-notification.yaml
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/ingress/$INGRESS/notification-ingress.yaml
    kubectl -n cno-system patch ing/cno-notification --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-notification.$INGRESS_DOMAIN'}]"

    # Install CNO UI
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-ui/cno-ui.yaml |
        sed 's|$API_URL|https://cno-api.'"$INGRESS_DOMAIN"'|g;  s|$NOTIFICATION_URL|https://cno-notification.'"$INGRESS_DOMAIN"'|g; s|$OIDC_URL|https://cno-auth.'"$INGRESS_DOMAIN"'|g; s|$OIDC_REALM|cno|g; s|$OIDC_CLIENT_ID|public|g' |
        kubectl -n cno-system apply -f -
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/ingress/$INGRESS/ui-ingress.yaml
    kubectl -n cno-system patch ing/cno-ui --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-ui.$INGRESS_DOMAIN'}]"

    # deploy cno-data-plane
    waitForRessourceCreated secrets $DEFAULT_AGENT_ID
    kubectl -n cno-system get secret/cno-kafka-cluster-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode > /tmp/cno-ca
    kubectl -n cno-system get secret/$DEFAULT_AGENT_ID -o jsonpath='{.data.user\.key}' | base64 --decode > /tmp/cno-kafka-key
    kubectl -n cno-system  get secret/$DEFAULT_AGENT_ID -o jsonpath='{.data.user\.crt}' | base64 --decode > /tmp/cno-kafka-cert
    kubectl -n cno-system create secret generic cno-agent-config --from-literal=licence=$DEFAULT_AGENT_ID --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key
    rm -rf /tmp/cno-*
    curl https://raw.githubusercontent.com/beopencloud/cno/feature/kafka-config/scripts/data-plane/install.sh > cnodataplane.sh
    chmod +x cnodataplane.sh
    ./cnodataplane.sh cno-kafka-cluster-kafka-bootstrap:9093
    rm -rf cnodataplane.sh

    echo
    echo "============================================================"
    echo "  INFO CNO installation success."
    echo "  INFO make sure ssl-passthrough is configured on your ingress controller. Otherwise, communication between cno components may not work correctly."
    echo "  INFO You Have to create the DNS mapping for the following URLs and you ingress controller"
    echo "  -->"
    printf "     "
    kubectl -n cno-system get ing -o jsonpath='{.items[*].spec.rules[*].host}' | sed -e 's| |\n     |g'
    echo
    echo "============================================================"
    echo


}

# waitForRessourceCreated resource resourceName
waitForRessourceCreated() {
    echo "waiting for resource $1 $2 ...";
    timeout=300
    resource=""
    while [ -z $resource ] && [ $timeout -gt 0 ];
    do
       resource=$(kubectl -n cno-system get $1 $2 -o jsonpath='{.metadata.name}')
       timeout=$((timeout - 5))
       sleep 5s
    done
    if [ ! $timeout -gt 0 ]; then
        echo "timeout: $1 $2 not found"
        return
    fi
    echo "$1 $2 successfully deployed"
}


hasKubectl
hasSetDomainSuffix
installCno

