#!/bin/sh

# Delete kafka operator
kubectl -n cno delete -f https://raw.githubusercontent.com/beopencloud/cno/main/files/kafkaStrimzi/crds/kafkaOperator.yaml

# Delete a kafka cluster
kubectl -n cno delete -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/kafka/kafka.yaml

# Delete the onboarding super-admin
kubectl -n cno  delete -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/kafka/onboardingSuperAdmin.yaml

# Delete keycloak Operator
kubectl -n cno delete -f  https://raw.githubusercontent.com/beopencloud/cno/main/deploy/keycloak/crds/keycloak-all.yaml


# Delete keycloak Cluster
kubectl delete -f  https://raw.githubusercontent.com/beopencloud/cno/main/deploy/keycloak/keycloak.yaml

# Delete Mysql DataBase and the Service
kubectl delete -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/mysqlDB/mysqlDB.yaml

# Delete Mysql PVC
kubectl delete -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/mysqlDB/pvc.yaml

# Delete CNO operator
kubectl delete -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/operator/cnoOperator/cno-operator-all.yaml

# Delete CNO service account, role and binding
kubectl delete -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/operator/templates/cno-rbac.yaml

# Installing Mysql Operator
helm install --name mysql-operator presslabs/mysql-operator 

# Delete CNO API
kubectl delete -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/onboarding-api/onboarding-api.yaml

# Delete CNO UI
kubectl delete -f https://raw.githubusercontent.com/beopencloud/cno/main/deploy/onboarding-ui/onboarding-ui.yaml

# Delete cno namespace
kubectl delete namespace cno