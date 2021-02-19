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
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/kafka.yaml
    sleep 5s
    kubectl -n cno-system wait -l statefulset.kubernetes.io/pod-name=kafka-cluster-zookeeper-2 --for=condition=ready pod --timeout=-1s
    sleep 5s
    kubectl -n cno-system wait -l statefulset.kubernetes.io/pod-name=kafka-cluster-kafka-2 --for=condition=ready pod --timeout=-1s
    
    # Create Kafka ingress and patch it with right domain prefix
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/ingress/$INGRESS/kafka-ingress.yaml
    kubectl -n cno-system patch ing/kafka-bootstrap --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-broker.$INGRESS_DOMAIN'}]"

    # Create cno kafka super-admin user
    kubectl -n cno-system  apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/cno-super-admin.yaml

    # Install keycloak Operator
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/crds/keycloak-all.yaml

    # Deploy keycloak Cluster and patch the ingress
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/keycloak.yaml
    #If PSP issue
    #kubectl -n cno-system patch deployment keycloak-postgresql --patch "$(curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/patch-psp-postgresql.yaml)"
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

    # Install CNO API
    kubectl -n cno-system get secret/kafka-cluster-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode > /tmp/cno-ca
    kubectl -n cno-system get secret/cno-kafka-superadmin -o jsonpath='{.data.user\.key}' | base64 --decode > /tmp/cno-kafka-key
    kubectl -n cno-system  get secret/cno-kafka-superadmin -o jsonpath='{.data.user\.crt}' | base64 --decode > /tmp/cno-kafka-cert
    kubectl  -n cno-system create secret generic kafkaconfig --from-literal=KAFKA_BROKERS=kafka-cluster-kafka-bootstrap --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key
    rm -rf /tmp/cno-*
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-api/cno-api.yaml
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/ingress/$INGRESS/api-ingress.yaml
    kubectl -n cno-system patch ing/cno-api --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-api.$INGRESS_DOMAIN'}]"


    # Install CNO UI
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-ui/cno-ui.yaml
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

hasKubectl
hasSetDomainSuffix
installCno

