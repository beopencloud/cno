#!/bin/sh

# Set VERSION to main if CNO_VERSION env variable is not set
# Ex: export CNO_VERSION="feature/mysql-operator"
[ -z "${CNO_VERSION}" ] && VERSION='main' || VERSION="${CNO_VERSION}"
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
# Delete ressources
## Delete the onboarding super-admin
$cmd kubectl -n cno-system  delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/kafka/cno-super-admin.yaml
## Delete a kafka cluster
$cmd kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/kafka/kafka.yaml
## Delete keycloak Cluster
$cmd kubectl -n cno-system delete -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/keycloak.yaml
## Delete CNO service account, role and binding
$cmd kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/templates/cno-rbac.yaml
# Delete CNO API
$cmd kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-api/cno-api.yaml
# Delete cluster
$cmd kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-api/cno-api-mysql.yaml
# Delete CNO UI
$cmd kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-ui/onboarding-ui.yaml
#Delete remaining resources
$cmd kubectl -n cno-system delete --all  all,ing,secret,cm


# Delete crds and operators
$cmd sleep 10
## Delete kafka operator
$cmd kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/kafka-strimzi/crds/kafkaOperator.yaml
## Delete keycloak Operator
$cmd kubectl -n cno-system delete -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/keycloak-all.yaml
## Delete CNO operator
$cmd kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/cnoOperator/cno-operator-all.yaml
## Delete Mysql Operator
$cmd kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/mysql-operator/mysql-operator.yaml


# Delete cno namespace
$cmd kubectl delete namespace cno-system
