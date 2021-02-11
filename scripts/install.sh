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

    # Deploy a kafka cluster
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/kafka.yaml

    # Create the onboarding super-admin
    kubectl -n cno-system  apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/onboardingSuperAdmin.yaml

    # Install keycloak Operator
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/crds/keycloak-all.yaml

    # Deploy keycloak Cluster and patch the ingress
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/keycloak.yaml
    kubectl -n cno-system apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/ingress/$INGRESS/keycloak-ingress.yaml
    kubectl -n cno-system patch ing/keycloak --type=json -p="[{'op': 'replace', 'path': '/spec/rules/0/host', 'value':'cno-login.$INGRESS_DOMAIN'}]"


    # Deploy CNO operator
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/cno-operator/cno-operator-all.yaml

    # Create CNO service account, role and binding
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/templates/cno-rbac.yaml

    # Install Mysql Operator
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/mysql-operator/mysql-operator.yaml

    # Install Mysql cluster 
    MYSQL_PWD=$(openssl rand -base64 14)
    kubectl -n cno-system create secret generic cno-api-db-secret  --from-literal=ROOT_PASSWORD="${MYSQL_PWD}"

    # Install CNO API
    kubectl -n cno-system get secret/kafka-cluster-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode > /tmp/cno-ca
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-api/onboarding-api.yaml

    # Install CNO UI
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-ui/onboarding-ui.yaml

    
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

