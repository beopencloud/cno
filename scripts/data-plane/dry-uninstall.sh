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


# Delete kafka operator
$cmd kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/data-plane/agent/cno-agent.yaml

# Delete a kafka cluster
$cmd kubectl -n cno-system delete -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/data-plane/cno-operator/cno-operator.yaml

#Delete remaining resources
$cmd kubectl -n cno-system delete --all  all,ing,secret,cm

# Delete cno namespace
$cmd kubectl delete namespace cno-system