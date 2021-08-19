#!/bin/sh

while getopts n: flag
do
    case "${flag}" in
        n) NAMESPACE=${OPTARG};;
    esac
done

#Setting git repository
CNO_RAW_REPOSITORY="https://raw.githubusercontent.com/beopencloud/cno"

#Setting registry images
KEYCLOAK_OPERATOR_IMAGE="quay.io/keycloak/keycloak-operator:12.0.1"
KEYCLOAK_IMAGE="quay.io/keycloak/keycloak:12.0.1"
KEYCLOAK_POSTGRESQL_IMAGE="registry.access.redhat.com/rhscl/postgresql-10-rhel7:1"
KAFKA_OPERATOR_IMAGE="strimzi/operator:0.20.0"
KAFKA_TOPIC_OPERATOR_IMAGE="strimzi/operator:0.20.0"
KAFKA_USER_OPERATOR_IMAGE="strimzi/operator:0.20.0"
KAFKA_TLS_SIDECAR_ENTITY_OPERATOR_IMAGE="strimzi/kafka:0.20.0-kafka-2.5.0"
KAFKA_BROKER_IMAGE="strimzi/kafka:0.20.0-kafka-2.5.0"
KAFKA_ZOOKEEPER_IMAGE="strimzi/kafka:0.20.0-kafka-2.5.0"
MYSQL_OPERATOR_IMAGE="quay.io/presslabs/mysql-operator:0.4.0"
MYSQL_OPERATOR_ORCHESTRATOR_IMAGE="quay.io/presslabs/mysql-operator-orchestrator:0.4.0"
MYSQL_IMAGE="percona@sha256:713c1817615b333b17d0fbd252b0ccc53c48a665d4cfcb42178167435a957322"
MYSQL_SIDECAR_IMAGE="quay.io/presslabs/mysql-operator-sidecar:0.4.0"
MYSQL_EXPORTER_IMAGE="prom/mysqld-exporter:v0.11.0"
CNO_API_IMAGE="beopenit/cno-api:latest"
CNO_NOTIFICATION_IMAGE="beopenit/cno-notification:v0.0.1-alpha"
CNO_UI_IMAGE="beopenit/cno-ui:latest"

# Set NAMESPACE to cno-system if -n flag is empty
[ -z "${NAMESPACE}" ] && NAMESPACE='cno-system'

# Set VERSION to main if CNO_VERSION env variable is not set
# Ex: export CNO_VERSION="feature/mysql-operator"
[ -z "${CNO_VERSION}" ] && VERSION='main' || VERSION="${CNO_VERSION}"

[ -z "${CNO_INSTALL_DATA_PLANE}" ] && INSTALL_DATA_PLANE='true' || INSTALL_DATA_PLANE="${CNO_INSTALL_DATA_PLANE}"

# Set INGRESS to nginx if CNO_INGRESS env variable is not set
# Ex: export CNO_INGRESS="nginx"
#[ -z "${CNO_INGRESS}" ] && INGRESS='nginx' || INGRESS="${CNO_INGRESS}"

if [ "${INSTALL_DATA_PLANE}" != 'true' ] && [ "${INSTALL_DATA_PLANE}" != 'false' ]; then
    echo "============================================================"
    echo "  CNO installation failed."
    echo "  INSTALL_DATA_PLANE value must be true or false."
    echo "============================================================"
    exit 1
fi

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

hasSetLoadBalancerIP() {
    if [ -z "${LOADBALANCER_IP}" ]; then
        echo "============================================================"
        echo "  CNO installation failed."
        echo "  The ip of a loadbalancer for your cluster nodes by exporting env variable LOADBALANCER_IP."
        echo "  Ex: $ export LOADBALANCER_IP=x.x.x.x"
        echo "============================================================"
        exit 1
    fi
}

installCno() {
    # Create cno namespace
    kubectl create namespace $NAMESPACE > /dev/null 2>&1

    # Install keycloak Operator
    curl  $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/keycloak/keycloak-all.yaml |
      sed -e 's|$KEYCLOAK_OPERATOR_IMAGE|'"$KEYCLOAK_OPERATOR_IMAGE"'|g; s|$KEYCLOAK_IMAGE|'"$KEYCLOAK_IMAGE"'|g; s|$KEYCLOAK_POSTGRESQL_IMAGE|'"$KEYCLOAK_POSTGRESQL_IMAGE"'|g' | kubectl -n $NAMESPACE apply -f -

    # Deploy keycloak Cluster and patch the service
    CLIENT_CNO_API=$(openssl rand -base64 14)
    kubectl -n $NAMESPACE create secret generic keycloak-client-cno-api  --from-literal=OIDC_CLIENT_SECRET="${CLIENT_CNO_API}"
    curl $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/keycloak/cno-realm-configmap.yml |
      sed -e 's|cno-api-client-secret|'"$CLIENT_CNO_API"'|g; s|$AUTH_URL|'"keycloak-discovery.$NAMESPACE.svc.cluster.local:8080"'|g' |
      kubectl -n $NAMESPACE apply -f  -
    kubectl -n $NAMESPACE apply -f  $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/keycloak/keycloak.yaml

    curl $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/keycloak/cno-realm.yml |
      kubectl -n $NAMESPACE apply -f  -

    #If PSP issue
    waitForResourceCreated deployment keycloak-postgresql
    if [ "${CNO_POD_POLICY_ACTIVITED}" = "true" ]; then
        kubectl -n $NAMESPACE patch deployment keycloak-postgresql --patch "$(curl --silent $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/keycloak/patch-psp-postgresql.yaml)"
    fi
    kubectl -n $NAMESPACE rollout status deploy keycloak-postgresql # Rollout keycloak postgres

    # Install kafka operator
    curl $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/operator/kafka-strimzi/crds/kafkaOperator.yaml | sed -e 's|$NAMESPACE|'"$NAMESPACE"'|g; s|$KAFKA_OPERATOR_IMAGE|'"$KAFKA_OPERATOR_IMAGE"'|g' | kubectl -n $NAMESPACE apply -f -
    kubectl -n $NAMESPACE rollout status deploy strimzi-cluster-operator

    # Deploy a kafka cluster
    curl $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/kafka/kafka-nodeport.yaml | sed -e 's|$KAFKA_TOPIC_OPERATOR_IMAGE|'"$KAFKA_TOPIC_OPERATOR_IMAGE"'|g; s|$KAFKA_USER_OPERATOR_IMAGE|'"$KAFKA_USER_OPERATOR_IMAGE"'|g; s|$KAFKA_TLS_SIDECAR_ENTITY_OPERATOR_IMAGE|'"$KAFKA_TLS_SIDECAR_ENTITY_OPERATOR_IMAGE"'|g; s|$KAFKA_BROKER_IMAGE|'"$KAFKA_BROKER_IMAGE"'|g; s|$KAFKA_ZOOKEEPER_IMAGE|'"$KAFKA_ZOOKEEPER_IMAGE"'|g' | kubectl -n $NAMESPACE apply -f -
    # waiting for zookeeper deployment
    waitForResourceCreated pod cno-kafka-cluster-zookeeper-0
    kubectl -n $NAMESPACE wait -l statefulset.kubernetes.io/pod-name=cno-kafka-cluster-zookeeper-0 --for=condition=ready pod --timeout=5m
    # waiting for kafka deployment
    waitForResourceCreated pod cno-kafka-cluster-kafka-0
    kubectl -n $NAMESPACE wait -l statefulset.kubernetes.io/pod-name=cno-kafka-cluster-kafka-0 --for=condition=ready pod --timeout=5m
    # Create cno kafka super-admin user
    kubectl -n $NAMESPACE  apply -f $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/kafka/cno-super-admin.yaml
    # Get the kafka brokers nodeport
    KAFKA_NODEPORT=$(kubectl -n $NAMESPACE get service cno-kafka-cluster-kafka-external-bootstrap -o=jsonpath='{.spec.ports[0].nodePort}{"\n"}')
    echo "  The node port number of the external bootstrap service is $KAFKA_NODEPORT"

    # Restart keycloak to reload realm cno
    curl $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/keycloak/cno-realm-configmap.yml |
      sed -e 's|cno-api-client-secret|'"$CLIENT_CNO_API"'|g; s|$AUTH_URL|'"keycloak-discovery.$NAMESPACE.svc.cluster.local:8080"'|g' |
      kubectl -n $NAMESPACE apply -f  -
    sleep 30s
    kubectl -n $NAMESPACE delete pod keycloak-0
    echo "  waiting recreate keycloak ..."
    kubectl -n $NAMESPACE wait pod keycloak-0 --for=condition=ready --timeout=5m


    # Install Mysql Operator
    curl $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/operator/mysql-operator/mysql-operator.yaml | sed -e 's|$NAMESPACE|'"$NAMESPACE"'|g; s|$MYSQL_OPERATOR_IMAGE|'"$MYSQL_OPERATOR_IMAGE"'|g; s|$MYSQL_SIDECAR_IMAGE|'"$MYSQL_SIDECAR_IMAGE"'|g; s|$MYSQL_EXPORTER_IMAGE|'"$MYSQL_EXPORTER_IMAGE"'|g; s|$MYSQL_OPERATOR_ORCHESTRATOR_IMAGE|'"$MYSQL_OPERATOR_ORCHESTRATOR_IMAGE"'|g' | kubectl -n $NAMESPACE apply -f -

    # Install Mysql cluster
    MYSQL_PWD=$(openssl rand -base64 14)
    kubectl -n $NAMESPACE create secret generic cno-api-db-secret  --from-literal=ROOT_PASSWORD="${MYSQL_PWD}"
    curl $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/onboarding-api/cno-api-mysql.yaml | sed -e 's|$MYSQL_IMAGE|'"$MYSQL_IMAGE"'|g' | kubectl -n $NAMESPACE apply -f -
    waitForResourceCreated pod cno-api-mysql-0
    kubectl -n $NAMESPACE wait -l statefulset.kubernetes.io/pod-name=cno-api-mysql-0 --for=condition=ready pod --timeout=5m
    sleep 10s
    kubectl -n $NAMESPACE exec -it cno-api-mysql-0 -c mysql -- mysql -u root -p$MYSQL_PWD -e "create database cnoapi"

    # Create CNO configMap
    kubectl create cm -n $NAMESPACE cno-config --from-literal OIDC_SERVER_BASE_URL=http://keycloak-discovery.$NAMESPACE.svc.cluster.local:8080 \
     --from-literal OIDC_REALM=cno-realm --from-literal KAFKA_BROKERS=kafka-cluster-kafka-external-bootstrap:9094 \
     --from-literal KAFKA_TLS_ENABLED="true"  --from-literal KAFKA_TOPIC_NOTIFICATION=cno-notification

    # kafka auth config
    kubectl -n $NAMESPACE get secret/cno-kafka-cluster-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/cno-ca
    kubectl -n $NAMESPACE get secret/cno-kafka-superadmin -o jsonpath='{.data.user\.key}' | base64 -d > /tmp/cno-kafka-key
    kubectl -n $NAMESPACE  get secret/cno-kafka-superadmin -o jsonpath='{.data.user\.crt}' | base64 -d > /tmp/cno-kafka-cert
    kubectl  -n $NAMESPACE create secret generic kafkaconfig --from-literal=KAFKA_BROKERS=kafka-cluster-kafka-bootstrap --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key
    # Clean
    rm -rf /tmp/cno-*

    # Install CNO API
    DEFAULT_AGENT_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
    SUPER_ADMIN_PASSWORD=$(kubectl -n $NAMESPACE get  secret credential-cloud-keycloak -o jsonpath="{.data.ADMIN_PASSWORD}" | base64 -d)
    DEFAULT_CLUSTER_API_SERVER_URL=$(kubectl config view --minify -o jsonpath='{.clusters[*].cluster.server}')
    kubectl -n $NAMESPACE create secret generic cno-super-admin-credential --from-literal=USERNAME=admin --from-literal=PASSWORD=$SUPER_ADMIN_PASSWORD
    curl $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/onboarding-api/cno-api.yaml |
        sed 's|$SUPER_ADMIN_PASSWORD|'"$SUPER_ADMIN_PASSWORD"'|g; s|$SERVER_URL|http://keycloak-discovery.'"$NAMESPACE"'.svc.cluster.local:8080|g; s|$OIDC_SERVER_BASE_URL|http://keycloak-discovery.'"$NAMESPACE"'.svc.cluster.local:8080|g; s|$OIDC_REALM|cno|g; s|$OIDC_CLIENT_ID|cno-api|g; s|$KAFKA_BROKERS|cno-kafka-cluster-kafka-bootstrap:9093|g; s|$DEFAULT_EXTERNAL_BROKERS_URL|'"$LOADBALANCER_IP"':'"$KAFKA_NODEPORT"'|g; s|$CREATE_DEFAULT_CLUSTER|"'"$INSTALL_DATA_PLANE"'"|g; s|$DEFAULT_CLUSTER_API_SERVER_URL|"'"$DEFAULT_CLUSTER_API_SERVER_URL"'"|g; s|$DEFAULT_CLUSTER_ID|'"$DEFAULT_AGENT_ID"'|g; s|ClusterIP|NodePort|g; s|$NAMESPACE|'"$NAMESPACE"'|g; s|$CNO_API_IMAGE|'"$CNO_API_IMAGE"'|g' |
        kubectl -n $NAMESPACE apply -f -
    kubectl -n $NAMESPACE rollout status deploy cno-api
    CNO_API_NODEPORT=$(kubectl -n $NAMESPACE get service cno-api -o=jsonpath='{.spec.ports[0].nodePort}{"\n"}')
    # Install CNO NOTIFICATION
    curl $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/notification/cno-notification.yaml | sed 's|ClusterIP|NodePort|g; s|$CNO_NOTIFICATION_IMAGE|'"$CNO_NOTIFICATION_IMAGE"'|g' | kubectl -n $NAMESPACE apply -f -
    CNO_NOTIFICATION_NODEPORT=$(kubectl -n $NAMESPACE get service cno-api -o=jsonpath='{.spec.ports[0].nodePort}{"\n"}')

    # Install CNO UI
    curl $CNO_RAW_REPOSITORY/$VERSION/deploy/control-plane/onboarding-ui/cno-ui.yaml |
        sed 's|$API_URL|https://'"$LOADBALANCER_IP"':'"$CNO_API_NODEPORT"'|g;  s|$NOTIFICATION_URL|https://'"$LOADBALANCER_IP"':'"$CNO_NOTIFICATION_NODEPORT"'|g; s|$OIDC_URL|http://keycloak-discovery.'"$NAMESPACE"'.svc.cluster.local:8080|g; s|$OIDC_REALM|cno|g; s|$OIDC_CLIENT_ID|public|g; s|ClusterIP|NodePort|g; s|$CNO_UI_IMAGE|'"$CNO_UI_IMAGE"'|g' |
        kubectl -n $NAMESPACE apply -f -
    CNO_UI_NODEPORT=$(kubectl -n $NAMESPACE get service cno-ui -o=jsonpath='{.spec.ports[0].nodePort}{"\n"}')

    if [ "${INSTALL_DATA_PLANE}" = 'true' ]; then
        # deploy cno-data-plane
        export KAFKA_BROKERS="cno-kafka-cluster-kafka-bootstrap:9093"
        waitForResourceCreated secrets $DEFAULT_AGENT_ID
        kubectl -n $NAMESPACE get secret/cno-kafka-cluster-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/cno-ca
        kubectl -n $NAMESPACE get secret/$DEFAULT_AGENT_ID -o jsonpath='{.data.user\.key}' | base64 -d > /tmp/cno-kafka-key
        kubectl -n $NAMESPACE  get secret/$DEFAULT_AGENT_ID -o jsonpath='{.data.user\.crt}' | base64 -d > /tmp/cno-kafka-cert
        kubectl -n $NAMESPACE create secret generic cno-agent-config --from-literal=licence=$DEFAULT_AGENT_ID --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key
        rm -rf /tmp/cno-*
        curl $CNO_RAW_REPOSITORY/$VERSION/scripts/data-plane/install.sh > cnodataplane.sh
        chmod +x cnodataplane.sh
        ./cnodataplane.sh -n $NAMESPACE
        rm -rf cnodataplane.sh
    fi

    echo
    echo "============================================================================================="
    echo "  INFO CNO installation success."
    echo "  You can access CNO at https://$LOADBALANCER_IP:$CNO_UI_NODEPORT"
    echo "  CNO Credentials USERNAME: admin    PASSWORD: $SUPER_ADMIN_PASSWORD"
    echo "============================================================================================="
    echo


}

# waitForResourceCreated resource resourceName
waitForResourceCreated() {
    echo "waiting for resource $1 $2 ...";
    timeout=300
    resource=""
    while [ -z $resource ] && [ $timeout -gt 0 ];
    do
       resource=$(kubectl -n $NAMESPACE get $1 $2 -o jsonpath='{.metadata.name}' --ignore-not-found)
       timeout=$((timeout - 5))
       sleep 5s
       if [ -z "${resource}" ]; then
           printf '...'
       fi
    done
    if [ ! "${timeout}" -gt 0 ]; then
        echo "timeout: $1 $2 not found"
        return
    fi
    echo "$1 $2 successfully deployed"
}


hasKubectl
hasSetLoadBalancerIP
installCno

