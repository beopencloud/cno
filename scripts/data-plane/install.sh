#!/bin/sh

# Set VERSION to main if CNO_VERSION env variable is not set
# Ex: export CNO_VERSION="feature/mysql-operator"
[ -z "${CNO_VERSION}" ] && VERSION='main' || VERSION="${CNO_VERSION}"

[ -z "${CNO_INSTALL_INGRESS_CONTROLLER}" ] && INSTALL_INGRESS_CONTROLLER='false' || INSTALL_INGRESS_CONTROLLER="${CNO_INSTALL_INGRESS_CONTROLLER}"

[ -z "${CNO_IS_AN_EKS_CLUSTER}" ] && IS_AN_EKS_CLUSTER='true' || IS_AN_EKS_CLUSTER="${CNO_IS_AN_EKS_CLUSTER}"

ingressControllerInstallation(){
    if [ $INSTALL_INGRESS_CONTROLLER = "true" ]; then
        NS_NGINX=$(kubectl get ns nginx-ingress -o jsonpath='{.metadata.name}' --ignore-not-found)
        if [ -z $NS_NGINX ]; then
            echo "nginx ingress controller will be installed"
        else
            if [ -z "${CNO_INSTALL_INGRESS_CONTROLLER}" ]; then
                INSTALL_INGRESS_CONTROLLER="false"
            else
                while true; do
                    read -p "Namespace nginx-ingress already exist ! would you like to overwrite you ingress controller (Y/n): " yn
                    case $yn in
                        [Yy]* ) INSTALL_INGRESS_CONTROLLER="true"; break;;
                        [Nn]* ) INSTALL_INGRESS_CONTROLLER="false"; break;;
                        * ) echo "Please answer yes or no.";;
                    esac
                done
            fi
        fi
        if [ -z $CNO_IS_AN_EKS_CLUSTER ]; then
            while true; do
                read -p "Is an EKS cluster (Y/n): " yn
                case $yn in
                    [Yy]* ) IS_AN_EKS_CLUSTER="true"; break;;
                    [Nn]* ) IS_AN_EKS_CLUSTER="false"; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        fi
        export IS_AN_EKS_CLUSTER=${IS_AN_EKS_CLUSTER}
        curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/ingress-controller/nginx/v1.11.1/install.sh > ingressControllerInstallation.sh
        chmod +x ingressControllerInstallation.sh
        ./ingressControllerInstallation.sh
        rm -rf ingressControllerInstallation.sh
    fi
}

hasKafkaBrokersUrl(){
    if [ -z "${KAFKA_BROKERS}" ]; then
        echo "============================================================"
        echo "  CNO installation failed."
        echo "  KAFKA_BROKERS is required."
        echo "  Ex: $ export KAFKA_BROKERS=bootstrap-cno.beopenit.com:443"
        echo "============================================================"
        exit 1
    fi
}

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

checkMetricsServer() {
    hasMetricsServer=$(kubectl top nodes)
    if [ -z "${hasMetricsServer}" ]; then
        echo "============================================================"
        echo "  WARNING Metrics Server not installed ! we will installed it."
        echo "============================================================"
        kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
        kubectl -n kube-system rollout status deployment metrics-server
    fi
}

genAgentConfig(){
    if [ -z "${CNO_AGENT_LICENCE}" ]; then
        echo "============================================================"
        echo " INFO CNO_AGENT_LICENCE environment variable is empty."
        echo " INFO skip secrets/cno-agent creation."
        echo "============================================================"
        return
    fi
    if [ -z "${CNO_AGENT_CA_CERT}" ]; then
        echo "============================================================"
        echo " INFO CNO_AGENT_CA_CERT environment variable is empty."
        echo " INFO skip secrets/cno-agent creation."
        echo "============================================================"
        return
    fi
    if [ -z "${CNO_AGENT_USER_CERT}" ]; then
        echo "============================================================"
        echo " INFO CNO_AGENT_USER_CERT environment variable is empty."
        echo " INFO skip secrets/cno-agent creation."
        echo "============================================================"
        return
    fi
    if [ -z "${CNO_AGENT_USER_KEY}" ]; then
        echo "============================================================"
        echo " INFO CNO_AGENT_USER_KEY environment variable is empty."
        echo " INFO skip secrets/cno-agent creation."
        echo "============================================================"
        return
    fi
    kubectl -n cno-system delete secret cno-agent-config
    echo $CNO_AGENT_CA_CERT | base64 -d > /tmp/cno-ca
    echo $CNO_AGENT_USER_CERT | base64 -d > /tmp/cno-kafka-cert
    echo $CNO_AGENT_USER_KEY | base64 -d > /tmp/cno-kafka-key
    kubectl -n cno-system create secret generic cno-agent-config --from-literal=licence=$CNO_AGENT_LICENCE --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key
    rm -rf /tmp/cno-*

    echo "============================================================"
    echo " INFO secrets/cno-agent-config successfully regenerated."
    echo "============================================================"
}

checkCnoAgentConfig(){
    hasConfig=$(kubectl -n cno-system get secrets cno-agent-config)
    if [ -z "${hasConfig}" ]; then
        echo "============================================================"
        echo "  ERROR secrets/cno-agent is required."
        echo "============================================================"
        exit 1
    fi
}

installCnoDataPlane() {
    # install cno-agent
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/data-plane/agent/cno-agent.yaml |
        sed 's|$KAFKA_BROKERS|'"$KAFKA_BROKERS"'|g' |
        kubectl -n cno-system apply -f -

    # install cno-operator
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/data-plane/cno-operator/cno-operator.yaml

    # install cno-cd-operator
    kubectl -n cno-system apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/data-plane/cno-cd/cno-cd-operator.yaml
}

# waitForRessourceCreated resource resourceName
waitForRessourceCreated() {
    echo "waiting for resource $1 $2 ...";
    timeout=120
    resource=""
    while [ -z "${resource}" ] && [ "${timeout}" -gt 0 ];
    do
       resource=$(kubectl -n cno-system get $1 $2 -o jsonpath='{.metadata.name}' --ignore-not-found)
       timeout=$((timeout - 5))
       sleep 5s
    done
    if [ ! "${timeout}" -gt 0 ]; then
        echo "timeout: $1 $2 not found"
        return
    fi
    echo "$1 $2 successfully deployed"
}
# Create cno namespace
kubectl create namespace cno-system > /dev/null 2>&1
hasKubectl
ingressControllerInstallation
checkMetricsServer
genAgentConfig
hasKafkaBrokersUrl
checkCnoAgentConfig
installCnoDataPlane

