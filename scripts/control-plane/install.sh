#!/bin/sh

# Set VERSION to main if CNO_VERSION env variable is not set
# Ex: export CNO_VERSION="feature/mysql-operator"
[ -z "${CNO_VERSION}" ] && VERSION='main' || VERSION="${CNO_VERSION}"

[ -z "${CNO_INSTALL_DATA_PLANE}" ] && INSTALL_DATA_PLANE='true' || INSTALL_DATA_PLANE="${CNO_INSTALL_DATA_PLANE}"

# Set INGRESS to nginx if CNO_INGRESS env variable is not set
# Ex: export CNO_INGRESS="nginx"
[ -z "${CNO_INGRESS}" ] && INGRESS='nginx' || INGRESS="${CNO_INGRESS}"

if [ "${INSTALL_DATA_PLANE}" != 'true' ] && [ "${INSTALL_DATA_PLANE}" != 'false' ]; then
    echo "============================================================"
    echo "  CNO installation failed."
    echo "  INSTALL_DATA_PLANE value must be true or false."
    echo "============================================================"
    exit 1
fi

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
    if [ -z "${INGRESS_DOMAIN}" ]; then
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
    kubectl create namespace cno-system > /dev/null 2>&1
    kubectl annotate namespace cno-system  openshift.io/sa.scc.supplemental-groups=999/100 openshift.io/sa.scc.uid-range=999/100 --overwrite > /dev/null 2>&1

    # Install keycloak Operator
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/keycloak-all.yaml

    # Deploy keycloak Cluster and patch the ingress
    CLIENT_CNO_API=$(openssl rand -base64 14)
    kubectl -n cno-system create secret generic keycloak-client-cno-api  --from-literal=OIDC_CLIENT_SECRET="${CLIENT_CNO_API}"
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/cno-realm-configmap.yml |
      sed -e 's|cno-api-client-secret|'"$CLIENT_CNO_API"'|g; s|$AUTH_URL|'"$INGRESS_DOMAIN"'|g' |
      kubectl -n cno-system apply -f  -
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/keycloak.yaml

    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/cno-realm.yml |
      kubectl -n cno-system apply -f  -

    #If PSP issue
    waitForResourceCreated deployment keycloak-postgresql
    if [ "${CNO_POD_POLICY_ACTIVITED}" = "true" ]; then
        kubectl -n cno-system patch deployment keycloak-postgresql --patch "$(curl --silent https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/patch-psp-postgresql.yaml)"
    fi
    kubectl -n cno-system rollout status deploy keycloak-postgresql # Rollout keycloak postgres
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/ingress/$INGRESS/keycloak-ingress.yaml
    kubectl -n cno-system patch ing/cno-keycloak --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-auth.$INGRESS_DOMAIN'}]"

    # Install kafka operator
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/kafka-strimzi/crds/kafkaOperator.yaml
    kubectl -n cno-system rollout status deploy strimzi-cluster-operator

    # Deploy a kafka cluster
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/kafka/kafka.yaml | sed -e 's|INGRESS_DOMAIN|'"$INGRESS_DOMAIN"'|g' | kubectl -n cno-system apply -f -
    # waiting for zookeeper deployment
    waitForResourceCreated pod cno-kafka-cluster-zookeeper-0
    kubectl -n cno-system wait -l statefulset.kubernetes.io/pod-name=cno-kafka-cluster-zookeeper-0 --for=condition=ready pod --timeout=5m
    # waiting for kafka deployment
    waitForResourceCreated pod cno-kafka-cluster-kafka-0
    kubectl -n cno-system wait -l statefulset.kubernetes.io/pod-name=cno-kafka-cluster-kafka-0 --for=condition=ready pod --timeout=5m
    # Create cno kafka super-admin user
    kubectl -n cno-system  apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/kafka/cno-super-admin.yaml

    # Restart keycloak to reload realm cno
    sleep 30s
    kubectl -n cno-system delete pod keycloak-0
    echo "  waiting recreate keycloak ..."
    kubectl -n cno-system wait pod keycloak-0 --for=condition=ready --timeout=5m


    # Install Mysql Operator
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/mysql-operator/mysql-operator.yaml

    # Install Mysql cluster
    MYSQL_PWD=$(openssl rand -base64 14)
    kubectl -n cno-system create secret generic cno-api-db-secret  --from-literal=ROOT_PASSWORD="${MYSQL_PWD}"
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-api/cno-api-mysql.yaml
    waitForResourceCreated pod cno-api-mysql-0
    kubectl -n cno-system wait -l statefulset.kubernetes.io/pod-name=cno-api-mysql-0 --for=condition=ready pod --timeout=5m
    sleep 10s
    kubectl -n cno-system exec -it cno-api-mysql-0 -- mysql -u root -p$MYSQL_PWD -e "create database cnoapi"

    # Create CNO configMap
    kubectl create cm -n cno-system cno-config --from-literal OIDC_SERVER_BASE_URL=https://cno-auth.$INGRESS_DOMAIN \
     --from-literal OIDC_REALM=cno-realm --from-literal KAFKA_BROKERS=kafka-cluster-kafka-external-bootstrap:9094 \
     --from-literal KAFKA_TLS_ENABLED="true"  --from-literal KAFKA_TOPIC_NOTIFICATION=cno-notification

    # kafka auth config
    kubectl -n cno-system get secret/cno-kafka-cluster-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/cno-ca
    kubectl -n cno-system get secret/cno-kafka-superadmin -o jsonpath='{.data.user\.key}' | base64 -d > /tmp/cno-kafka-key
    kubectl -n cno-system  get secret/cno-kafka-superadmin -o jsonpath='{.data.user\.crt}' | base64 -d > /tmp/cno-kafka-cert
    kubectl  -n cno-system create secret generic kafkaconfig --from-literal=KAFKA_BROKERS=kafka-cluster-kafka-bootstrap --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key
    # Clean
    rm -rf /tmp/cno-*

    # Install CNO API
    DEFAULT_AGENT_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
    SUPER_ADMIN_PASSWORD=$(kubectl -n cno-system get  secret credential-cloud-keycloak -o jsonpath="{.data.ADMIN_PASSWORD}" | base64 -d)
    DEFAULT_CLUSTER_API_SERVER_URL=$(kubectl config view --minify -o jsonpath='{.clusters[*].cluster.server}')
    kubectl -n cno-system create secret generic cno-super-admin-credential --from-literal=USERNAME=admin --from-literal=PASSWORD=$SUPER_ADMIN_PASSWORD
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-api/cno-api.yaml |
        sed 's|$SUPER_ADMIN_PASSWORD|'"$SUPER_ADMIN_PASSWORD"'|g; s|$SERVER_URL|https://cno-api.'"$INGRESS_DOMAIN"'|g; s|$OIDC_SERVER_BASE_URL|https://cno-auth.'"$INGRESS_DOMAIN"'|g; s|$OIDC_REALM|cno|g; s|$OIDC_CLIENT_ID|cno-api|g; s|$KAFKA_BROKERS|cno-kafka-cluster-kafka-bootstrap:9093|g; s|$DEFAULT_EXTERNAL_BROKERS_URL|bootstrap-cno.'"$INGRESS_DOMAIN"':443|g; s|$CREATE_DEFAULT_CLUSTER|"'"$INSTALL_DATA_PLANE"'"|g; s|$DEFAULT_CLUSTER_API_SERVER_URL|"'"$DEFAULT_CLUSTER_API_SERVER_URL"'"|g; s|$DEFAULT_CLUSTER_ID|'"$DEFAULT_AGENT_ID"'|g' |
        kubectl -n cno-system apply -f -
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/ingress/$INGRESS/api-ingress.yaml
    kubectl -n cno-system patch ing/cno-api --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-api.$INGRESS_DOMAIN'}]"
    kubectl -n cno-system rollout status deploy cno-api
    # Install CNO NOTIFICATION
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/notification/cno-notification.yaml
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/ingress/$INGRESS/notification-ingress.yaml
    kubectl -n cno-system patch ing/cno-notification --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-notification.$INGRESS_DOMAIN'}]"

    # Install CNO UI
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-ui/cno-ui.yaml |
        sed 's|$API_URL|https://cno-api.'"$INGRESS_DOMAIN"'|g;  s|$NOTIFICATION_URL|https://cno-notification.'"$INGRESS_DOMAIN"'|g; s|$OIDC_URL|https://cno-auth.'"$INGRESS_DOMAIN"'|g; s|$OIDC_REALM|cno|g; s|$OIDC_CLIENT_ID|public|g' |
        kubectl -n cno-system apply -f -
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/ingress/$INGRESS/ui-ingress.yaml
    kubectl -n cno-system patch ing/cno-ui --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno.$INGRESS_DOMAIN'}]"

    if [ "${INSTALL_DATA_PLANE}" = 'true' ]; then
        # deploy cno-data-plane
        export KAFKA_BROKERS="cno-kafka-cluster-kafka-bootstrap:9093"
        waitForResourceCreated secrets $DEFAULT_AGENT_ID
        kubectl -n cno-system get secret/cno-kafka-cluster-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/cno-ca
        kubectl -n cno-system get secret/$DEFAULT_AGENT_ID -o jsonpath='{.data.user\.key}' | base64 -d > /tmp/cno-kafka-key
        kubectl -n cno-system  get secret/$DEFAULT_AGENT_ID -o jsonpath='{.data.user\.crt}' | base64 -d > /tmp/cno-kafka-cert
        kubectl -n cno-system create secret generic cno-agent-config --from-literal=licence=$DEFAULT_AGENT_ID --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key
        rm -rf /tmp/cno-*
        curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/scripts/data-plane/install.sh > cnodataplane.sh
        chmod +x cnodataplane.sh
        ./cnodataplane.sh
        rm -rf cnodataplane.sh
    fi

    echo
    echo "============================================================================================="
    echo "  INFO CNO installation success."
    echo "  cno.$INGRESS_DOMAIN CNO Credentials USERNAME: admin    PASSWORD: $SUPER_ADMIN_PASSWORD"
    echo "============================================================================================="
    echo


}

# waitForResourceCreated resource resourceName
waitForResourceCreated() {
    echo "waiting for resource $1 $2 ...";
    timeout=300
    resource=""
    while [ -z $resource ] && [ $timeout -gt 0 ];
    do
       resource=$(kubectl -n cno-system get $1 $2 -o jsonpath='{.metadata.name}' --ignore-not-found)
       timeout=$((timeout - 5))
       sleep 5s
       if [ -z "${resource}" ]; then
           printf '...'
       fi
    done
    if [ ! "${timeout}" -gt 0 ]; then
        echo "timeout: $1 $2 not found"
        return
    fi
    echo "$1 $2 successfully deployed"
}


hasKubectl
hasSetDomainSuffix
installCno

