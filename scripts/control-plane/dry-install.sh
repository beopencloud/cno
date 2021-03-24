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

dry_run=false

while getopts 'd' opt; do
    case "$opt" in
        d) dry_run=true ;;
        *) echo 'error in command line parsing' >&2
           exit 1
    esac
done

if "$dry_run"; then
    cmd=echo
else
    cmd=''
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
    $cmd  kubectl create namespace cno-system > /dev/null 2>&1

    # Install keycloak Operator
   $cmd kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/keycloak-all.yaml

    # Deploy keycloak Cluster and patch the ingress
    CLIENT_CNO_API=$(openssl rand -base64 14)
    $cmd kubectl -n cno-system create secret generic keycloak-client-cno-api  --from-literal=OIDC_CLIENT_SECRET="${CLIENT_CNO_API}"
    $cmd curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/cno-realm-configmap.yml |
    $cmd  sed -e 's|cno-api-client-secret|'"$CLIENT_CNO_API"'|g; s|$AUTH_URL|'"$INGRESS_DOMAIN"'|g' |
    $cmd  kubectl -n cno-system apply -f  -
    $cmd kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/keycloak.yaml

    $cmd curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/cno-realm.yml |
    $cmd  kubectl -n cno-system apply -f  -

    #If PSP issue
    $cmd waitForResourceCreated deployment keycloak-postgresql
    if [ "${CNO_POD_POLICY_ACTIVITED}" = "true" ]; then
    $cmd    kubectl -n cno-system patch deployment keycloak-postgresql --patch "$(curl --silent https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/patch-psp-postgresql.yaml)"
    fi
     $cmd kubectl -n cno-system rollout status deploy keycloak-postgresql # Rollout keycloak postgres
    $cmd kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/ingress/$INGRESS/keycloak-ingress.yaml
    $cmd kubectl -n cno-system patch ing/cno-keycloak --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-auth.$INGRESS_DOMAIN'}]"

    # Install kafka operator
    $cmd kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/kafka-strimzi/crds/kafkaOperator.yaml
    $cmd kubectl -n cno-system rollout status deploy strimzi-cluster-operator

    # Deploy a kafka cluster
    $cmd curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/kafka/kafka.yaml | sed -e 's|INGRESS_DOMAIN|'"$INGRESS_DOMAIN"'|g' | kubectl -n cno-system apply -f -
    # waiting for zookeeper deployment
    $cmd waitForResourceCreated pod cno-kafka-cluster-zookeeper-0
    $cmd kubectl -n cno-system wait -l statefulset.kubernetes.io/pod-name=cno-kafka-cluster-zookeeper-0 --for=condition=ready pod --timeout=5m
    # waiting for kafka deployment
    $cmd waitForResourceCreated pod cno-kafka-cluster-kafka-0
    $cmd kubectl -n cno-system wait -l statefulset.kubernetes.io/pod-name=cno-kafka-cluster-kafka-0 --for=condition=ready pod --timeout=5m
    # Create cno kafka super-admin user
    $cmd kubectl -n cno-system  apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/kafka/cno-super-admin.yaml

    # Restart keycloak to reload realm cno
    $cmd sleep 30s
    $cmd kubectl -n cno-system delete pod keycloak-0
    echo "  waiting recreate keycloak ..."
    $cmd kubectl -n cno-system wait pod keycloak-0 --for=condition=ready --timeout=5m


    # Install Mysql Operator
    $cmd kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/mysql-operator/mysql-operator.yaml

    # Install Mysql cluster
    MYSQL_PWD=$(openssl rand -base64 14)
    $cmd kubectl -n cno-system create secret generic cno-api-db-secret  --from-literal=ROOT_PASSWORD="${MYSQL_PWD}"
    $cmd kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-api/cno-api-mysql.yaml
    $cmd waitForResourceCreated pod cno-api-mysql-0
    $cmd kubectl -n cno-system wait -l statefulset.kubernetes.io/pod-name=cno-api-mysql-0 --for=condition=ready pod --timeout=5m
    sleep 10s
    $cmd kubectl -n cno-system exec -it cno-api-mysql-0 -- mysql -u root -p$MYSQL_PWD -e "create database cnoapi"

    # Create CNO configMap
    $cmd kubectl create cm -n cno-system cno-config --from-literal OIDC_SERVER_BASE_URL=https://cno-auth.$INGRESS_DOMAIN \
     --from-literal OIDC_REALM=cno-realm --from-literal KAFKA_BROKERS=kafka-cluster-kafka-external-bootstrap:9094 \
     --from-literal KAFKA_TLS_ENABLED="true"  --from-literal KAFKA_TOPIC_NOTIFICATION=cno-notification

    # kafka auth config
    $cmd kubectl -n cno-system get secret/cno-kafka-cluster-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode > /tmp/cno-ca
    $cmd kubectl -n cno-system get secret/cno-kafka-superadmin -o jsonpath='{.data.user\.key}' | base64 --decode > /tmp/cno-kafka-key
    $cmd kubectl -n cno-system  get secret/cno-kafka-superadmin -o jsonpath='{.data.user\.crt}' | base64 --decode > /tmp/cno-kafka-cert
    kubectl  -n cno-system create secret generic kafkaconfig --from-literal=KAFKA_BROKERS=kafka-cluster-kafka-bootstrap --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key
    # Clean
    rm -rf /tmp/cno-*

    # Install CNO API
    DEFAULT_AGENT_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
    SUPER_ADMIN_PASSWORD=$(openssl rand -base64 14)
    DEFAULT_CLUSTER_API_SERVER_URL=$(kubectl config view --minify -o jsonpath='{.clusters[*].cluster.server}')
    $cmd kubectl -n cno-system create secret generic cno-super-admin-credential --from-literal=USERNAME=admin --from-literal=PASSWORD=$SUPER_ADMIN_PASSWORD
    $cmd curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-api/cno-api.yaml |
        sed 's|$SUPER_ADMIN_PASSWORD|'"$SUPER_ADMIN_PASSWORD"'|g; s|$SERVER_URL|https://cno-api.'"$INGRESS_DOMAIN"'|g; s|$OIDC_SERVER_BASE_URL|https://cno-auth.'"$INGRESS_DOMAIN"'|g; s|$OIDC_REALM|cno|g; s|$OIDC_CLIENT_ID|cno-api|g; s|$KAFKA_BROKERS|cno-kafka-cluster-kafka-bootstrap:9093|g; s|$DEFAULT_EXTERNAL_BROKERS_URL|bootstrap-cno.'"$INGRESS_DOMAIN"':443|g; s|$CREATE_DEFAULT_CLUSTER|"'"$INSTALL_DATA_PLANE"'"|g; s|$DEFAULT_CLUSTER_API_SERVER_URL|"'"$DEFAULT_CLUSTER_API_SERVER_URL"'"|g; s|$DEFAULT_CLUSTER_ID|'"$DEFAULT_AGENT_ID"'|g' |
    $cmd    kubectl -n cno-system apply -f -
    $cmd kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/ingress/$INGRESS/api-ingress.yaml
    $cmd kubectl -n cno-system patch ing/cno-api --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-api.$INGRESS_DOMAIN'}]"
    $cmd kubectl -n cno-system rollout status deploy cno-api
    # Install CNO NOTIFICATION
    $cmd kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/notification/cno-notification.yaml
    $cmd kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/ingress/$INGRESS/notification-ingress.yaml
    $cmd kubectl -n cno-system patch ing/cno-notification --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-notification.$INGRESS_DOMAIN'}]"

    # Install CNO UI
    $cmd curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-ui/cno-ui.yaml |
        sed 's|$API_URL|https://cno-api.'"$INGRESS_DOMAIN"'|g;  s|$NOTIFICATION_URL|https://cno-notification.'"$INGRESS_DOMAIN"'|g; s|$OIDC_URL|https://cno-auth.'"$INGRESS_DOMAIN"'|g; s|$OIDC_REALM|cno|g; s|$OIDC_CLIENT_ID|public|g' |
    $cmd    kubectl -n cno-system apply -f -
    $cmd kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/ingress/$INGRESS/ui-ingress.yaml
    $cmd kubectl -n cno-system patch ing/cno-ui --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno.$INGRESS_DOMAIN'}]"

    if [ "${INSTALL_DATA_PLANE}" = 'true' ]; then
        # deploy cno-data-plane
        export KAFKA_BROKERS="cno-kafka-cluster-kafka-bootstrap:9093"
        $cmd waitForResourceCreated secrets $DEFAULT_AGENT_ID
        $cmd kubectl -n cno-system get secret/cno-kafka-cluster-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode > /tmp/cno-ca
        $cmd kubectl -n cno-system get secret/$DEFAULT_AGENT_ID -o jsonpath='{.data.user\.key}' | base64 --decode > /tmp/cno-kafka-key
        $cmd kubectl -n cno-system  get secret/$DEFAULT_AGENT_ID -o jsonpath='{.data.user\.crt}' | base64 --decode > /tmp/cno-kafka-cert
        $cmd kubectl -n cno-system create secret generic cno-agent-config --from-literal=licence=$DEFAULT_AGENT_ID --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key
        $cmd rm -rf /tmp/cno-*
        $cmd curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/scripts/data-plane/install.sh > cnodataplane.sh
        $cmd chmod +x cnodataplane.sh
        $cmd ./cnodataplane.sh
        rm -rf cnodataplane.sh
    fi

    echo
    echo "============================================================"
    echo "  INFO CNO installation success."
    echo "  INFO make sure ssl-passthrough is configured on your ingress controller. Otherwise, communication between cno components may not work correctly."
    echo "  INFO You Have to create the DNS mapping for the following URLs and you ingress controller"
    echo "  -->"
    printf "     "
    $cmd kubectl -n cno-system get ing -o jsonpath='{.items[*].spec.rules[*].host}' | sed -e 's| |\n     |g'
    echo "  CNO Credentials USERNAME: admin    PASSWORD: $SUPER_ADMIN_PASSWORD"
    $cmd username=$(kubectl -n cno-system get secrets credential-cloud-keycloak -o jsonpath='{.data.ADMIN_USERNAME}' | base64 --decode)
    password=$(kubectl -n cno-system get secrets credential-cloud-keycloak -o jsonpath='{.data.ADMIN_PASSWORD}' | base64 --decode)
    echo "  KEYCLOAK master realm credentials: USERNAME: $username       PASSWORD: $password"
    echo
    echo "============================================================"
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

