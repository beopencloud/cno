#!/bin/sh

# Set VERSION to main if CNO_VERSION env variable is not set
# Ex: export CNO_VERSION="feature/mysql-operator"
[[ -z "${CNO_VERSION}" ]] && VERSION='main' || VERSION="${CNO_VERSION}"


# Delete kafka operator
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/kafka-strimzi/crds/kafkaOperator.yaml

# Delete a kafka cluster
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/kafka.yaml

# Delete the onboarding super-admin
kubectl -n cno-system  delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/cno-super-admin.yaml

# Delete keycloak Operator
kubectl -n cno-system delete -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/crds/keycloak-all.yaml


# Delete keycloak Cluster
kubectl -n cno-system delete -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/keycloak.yaml

# Delete CNO operator
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/cnoOperator/cno-operator-all.yaml

# Delete CNO service account, role and binding
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/templates/cno-rbac.yaml

# Delete CNO API
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-api/cno-api.yaml

# Delete Mysql Operator and cluster
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-api/cno-api-mysql.yaml
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/mysql-operator/mysql-operator.yaml

# Delete CNO UI
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-ui/onboarding-ui.yaml

#Delete remaining resources
kubectl -n cno-system delete --all  all,ing,secret,cm

curl https://raw.githubusercontent.com/beopencloud/cno/feature/kafka-config/scripts/data-plane/uninstall.sh > uninstallcnodataplane.sh
    chmod +x uninstallcnodataplane.sh
    ./uninstallcnodataplane.sh
    rm -rf uninstallcnodataplane.sh

# Delete cno namespace
#kubectl delete namespace cno-system