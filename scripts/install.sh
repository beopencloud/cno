#!/bin/sh

VERSION="feature/mysql-operator"

hasKubectl() {
    hasKubectl=$(which kubectl)
    if [ "$?" = "1" ]; then
        echo "You need kubectl to use this script."
        exit 1
    fi
}

installCno() {
    # Create cno namespace
    kubectl create namespace cno-system

    # Install kafka operator
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/kafka-strimzi/crds/kafkaOperator.yaml

    # Deploy a kafka cluster
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/kafka.yaml

    # Create the onboarding super-admin
    kubectl -n cno-system  apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/onboardingSuperAdmin.yaml

    # Install keycloak Operator
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/crds/keycloak-all.yaml


    # Deploy keycloak Cluster
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/keycloak.yaml

    # Deploy CNO operator
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/cno-operator/cno-operator-all.yaml

    # Create CNO service account, role and binding
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/templates/cno-rbac.yaml

    # Install Mysql Operator
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/mysql-operator/mysql-operator.yaml

    # Install Mysql cluster 
    MYSQL_PWD=$(openssl rand -base64 14)
    kubectl -n cno-system create secret generic mysql-secret  --from-literal=ROOT_PASSWORD="${MYSQL_PWD}"

    # Install CNO API
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-api/onboarding-api.yaml

    # Install CNO UI
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-ui/onboarding-ui.yaml

    #Fetch  NodePort  services ports
    API_PORT = $(kubectl get svc cno-api-nport  -o jsonpath='{.spec.ports[0].nodePort}')
    echo
    echo "============================================================"
    echo "  CNO installation success."
    echo "  Mysql cluster root password : ${MYSQL_PWD}"
    echo "  UI url : "
    echo "============================================================"
    echo

}

hasKubectl
installCno

