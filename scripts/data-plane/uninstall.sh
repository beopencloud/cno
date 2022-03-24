#!/bin/sh

while getopts n: flag
do
    case "${flag}" in
        n) NAMESPACE=${OPTARG};;
    esac
done

# Set NAMESPACE to cno-system if -n flag is empty
[ -z "${NAMESPACE}" ] && NAMESPACE='cno-system'

# Set VERSION to main if CNO_VERSION env variable is not set
# Ex: export CNO_VERSION="feature/mysql-operator"
[ -z "${CNO_VERSION}" ] && VERSION='main' || VERSION="${CNO_VERSION}"


# Delete kafka operator
kubectl -n $NAMESPACE delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/data-plane/agent/cno-agent.yaml

# Delete a kafka cluster
kubectl -n $NAMESPACE delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/data-plane/cno-operator/cno-operator.yaml

#Delete remaining resources
kubectl -n $NAMESPACE delete --all  all,ing,secret,cm

# Delete cno namespace
kubectl delete namespace $NAMESPACE