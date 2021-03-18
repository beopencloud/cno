#!/bin/bash

# Set VERSION to main if CNO_VERSION env variable is not set
# Ex: export CNO_VERSION="feature/mysql-operator"
[[ -z "${CNO_VERSION}" ]] && VERSION='main' || VERSION="${CNO_VERSION}"

# Delete ressources
## Delete the onboarding super-admin
kubectl -n cno-system  delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/kafka/cno-super-admin.yaml
## Delete a kafka cluster
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/kafka/kafka.yaml
## Delete keycloak Cluster
kubectl -n cno-system delete -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/keycloak.yaml
## Delete CNO service account, role and binding
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/templates/cno-rbac.yaml
# Delete CNO API
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-api/cno-api.yaml
# Delete cluster
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-api/cno-api-mysql.yaml
# Delete CNO UI
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-ui/onboarding-ui.yaml
#Delete remaining resources
kubectl -n cno-system delete --all  all,ing,secret,cm


# Delete crds and operators
sleep 10
## Delete kafka operator
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/kafka-strimzi/crds/kafkaOperator.yaml
## Delete keycloak Operator
kubectl -n cno-system delete -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/keycloak-all.yaml
## Delete CNO operator
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/cnoOperator/cno-operator-all.yaml
## Delete Mysql Operator
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/mysql-operator/mysql-operator.yaml


# Delete cno namespace
kubectl delete namespace cno-system
