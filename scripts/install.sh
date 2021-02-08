#!/bin/sh

hasKubectl() {
    hasKubectl=$(which kubectl)
    if [ "$?" = "1" ]; then
        echo "You need kubectl to use this script."
        exit 1
    fi
}

hasHelm() {
    hasHelm=$(which helm)
    if [ "$?" = "1" ]; then
        echo "You need helm to use this script."
        exit 1
    fi
}

installCno() {
    # Create cno namespace
    kubectl create namespace cno

    # Install kafka operator
    kubectl -n cno apply -f https://raw.githubusercontent.com/beopencloud/cno/main/files/kafkaStrimzi/crds/kafkaOperator.yaml

    # Deploy a kafka cluster
    kubectl -n cno apply -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/kafka/kafka.yaml

    # Create the onboarding super-admin
    kubectl -n cno  apply -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/kafka/onboardingSuperAdmin.yaml

    # Install keycloak Operator
    kubectl -n cno apply -f  https://raw.githubusercontent.com/beopencloud/cno/main/deploy/keycloak/crds/keycloak-all.yaml


    # Deploy keycloak Cluster
    kubectl apply -f  https://raw.githubusercontent.com/beopencloud/cno/main/deploy/keycloak/keycloak.yaml

    # Create Mysql DataBase and the Service
    kubectl apply -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/mysqlDB/mysqlDB.yaml

    # Create Mysql PVC
    kubectl apply -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/mysqlDB/pvc.yaml

    # Deploy CNO operator
    kubectl apply -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/operator/cnoOperator/cno-operator-all.yaml

    # Create CNO service account, role and binding
    kubectl apply -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/operator/templates/cno-rbac.yaml

    # Installing Mysql Operator
    helm repo add presslabs https://presslabs.github.io/charts
    helm install  mysql-operator presslabs/mysql-operator  -n cno

    # Install CNO API
    kubectl apply -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/onboarding-api/onboarding-api.yaml

    # Install CNO UI
    kubectl apply -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/onboarding-ui/onboarding-ui.yaml

}

hasKubectl
hasHelm
installCno

