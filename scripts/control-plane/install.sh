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

    # Install CNO API
    kubectl -n cno-system get secret/cno-kafka-cluster-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode > /tmp/cno-ca
    kubectl -n cno-system get secret/cno-kafka-superadmin -o jsonpath='{.data.user\.key}' | base64 --decode > /tmp/cno-kafka-key
    kubectl -n cno-system  get secret/cno-kafka-superadmin -o jsonpath='{.data.user\.crt}' | base64 --decode > /tmp/cno-kafka-cert
    kubectl  -n cno-system create secret generic kafkaconfig --from-literal=KAFKA_BROKERS=kafka-cluster-kafka-bootstrap --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key
    rm -rf /tmp/cno-*
    DEFAULT_AGENT_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-api/cno-api.yaml |
        sed 's|$SERVER_URL|https://cno-api.'"$INGRESS_DOMAIN"'|g; s|$OIDC_SERVER_URL|https://cno-auth.'"$INGRESS_DOMAIN"'/auth/realms/cno/|g; s|$OIDC_SERVER_BASE_URL|https://cno-auth.'"$INGRESS_DOMAIN"'|g; s|$OIDC_REALM|cno|g; s|$OIDC_CLIENT_ID|cno-api|g; s|$KAFKA_BROKERS|cno-kafka-cluster-kafka-bootstrap:9093|g; s|$CREATE_DEFAULT_CLUSTER|"true"|g; s|$DEFAULT_CLUSTER_ID|'"$DEFAULT_AGENT_ID"'|g' |
        kubectl -n cno-system apply -f -
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/ingress/$INGRESS/api-ingress.yaml
    kubectl -n cno-system patch ing/cno-api --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-api.$INGRESS_DOMAIN'}]"
    kubectl -n cno-system rollout status deploy cno-api

    waitForRessourceCreated secrets $DEFAULT_AGENT_ID
    kubectl -n cno-system get secret/$DEFAULT_AGENT_ID -o jsonpath='{.data.ca\.crt}' | base64 --decode > /tmp/cno-ca
    kubectl -n cno-system get secret/$DEFAULT_AGENT_ID -o jsonpath='{.data.user\.key}' | base64 --decode > /tmp/cno-kafka-key
    kubectl -n cno-system  get secret/$DEFAULT_AGENT_ID -o jsonpath='{.data.user\.crt}' | base64 --decode > /tmp/cno-kafka-cert
    kubectl  -n cno-system create secret generic kafkaconfig-$DEFAULT_AGENT_ID --from-literal=KAFKA_BROKERS=kafka-cluster-kafka-bootstrap --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key


    # Install CNO UI
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-ui/cno-ui.yaml
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-ui/cno-ui.yaml |
        sed 's|$API_URL|https://cno-api.'"$INGRESS_DOMAIN"'|g;  s|$NOTIFICATION_URL|https://cno-notification.'"$INGRESS_DOMAIN"'|g; s|$OIDC_URL|https://cno-auth.'"$INGRESS_DOMAIN"'/auth/realms/cno/|g; s|$OIDC_REALM|cno|g; s|$OIDC_CLIENT_ID|public|g' |
        kubectl -n cno-system apply -f -
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/ingress/$INGRESS/ui-ingress.yaml
    kubectl -n cno-system patch ing/cno-ui --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-ui.$INGRESS_DOMAIN'}]"

    
    echo
    echo "============================================================"
    echo "  CNO installation success."
    echo "  Mysql Cluster root password : ${MYSQL_PWD}"
    echo "  UI url : "
    echo "============================================================"
    echo

}

# waitForRessourceCreated resource resourceName
waitForRessourceCreated() {
    echo "waiting for resource $1 $2 ...";
    timeout=120
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

installCnoTest(){
    kubectl -n cno-system rollout status deploy strimzi-cluster-operator

    # Deploy a kafka cluster
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/kafka.yaml | sed -e 's|INGRESS_DOMAIN|'"$INGRESS_DOMAIN"'|g' | kubectl -n cno-system apply -f -
    # waiting for zookeeper deployment
    waitForRessourceCreated pod cno-kafka-cluster-zookeeper-0
    kubectl -n cno-system wait -l statefulset.kubernetes.io/pod-name=cno-kafka-cluster-zookeeper-0 --for=condition=ready pod --timeout=1m
    # waiting for kafka deployment
    waitForRessourceCreated pod cno-kafka-cluster-kafka-0
    kubectl -n cno-system wait -l statefulset.kubernetes.io/pod-name=cno-kafka-cluster-kafka-0 --for=condition=ready pod --timeout=1m
    # Create cno kafka super-admin user
    kubectl -n cno-system  apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/cno-super-admin.yaml

}

#installCnoTest
hasKubectl
hasSetDomainSuffix
installCno

