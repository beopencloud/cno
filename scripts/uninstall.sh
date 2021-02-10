#!/bin/sh

VERSION="feature/mysql-operator"


# Delete kafka operator
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/kafka-strimzi/crds/kafkaOperator.yaml

# Delete a kafka cluster
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/kafka.yaml

# Delete the onboarding super-admin
kubectl -n cno-system  delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/kafka/onboardingSuperAdmin.yaml

# Delete keycloak Operator
kubectl -n cno-system delete -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/crds/keycloak-all.yaml


# Delete keycloak Cluster
kubectl -n cno-system delete -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/keycloak/keycloak.yaml

# Delete CNO operator
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/cnoOperator/cno-operator-all.yaml

# Delete CNO service account, role and binding
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/operator/templates/cno-rbac.yaml

# Delete CNO API
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-api/onboarding-api.yaml

# Delete CNO UI
kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/onboarding-ui/onboarding-ui.yaml

#Delete remaining resources
kubectl -n cno-system delete --all  all

# Delete cno namespace
kubectl delete namespace cno-system