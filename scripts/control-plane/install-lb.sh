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

installCno() {
    # Create cno namespace
    kubectl create namespace $NAMESPACE > /dev/null 2>&1

    # Install keycloak Operator
    kubectl -n $NAMESPACE apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/keycloak-all.yaml

    # Deploy keycloak Cluster and patch the service
    CLIENT_CNO_API=$(openssl rand -base64 14)
    kubectl -n $NAMESPACE create secret generic keycloak-client-cno-api  --from-literal=OIDC_CLIENT_SECRET="${CLIENT_CNO_API}"
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/cno-realm-configmap.yml |
      sed -e 's|cno-api-client-secret|'"$CLIENT_CNO_API"'|g; s|$AUTH_URL|keycloak-discovery.'"$NAMESPACE"'.svc.cluster.local:8080|g' |
      kubectl -n $NAMESPACE apply -f  -
    kubectl -n $NAMESPACE apply -f  https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/keycloak.yaml

    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/cno-realm.yml |
      kubectl -n $NAMESPACE apply -f  -

    #If PSP issue
    waitForResourceCreated deployment keycloak-postgresql
    if [ "${CNO_POD_POLICY_ACTIVITED}" = "true" ]; then
        kubectl -n $NAMESPACE patch deployment keycloak-postgresql --patch "$(curl --silent https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/keycloak/patch-psp-postgresql.yaml)"
    fi
    kubectl -n $NAMESPACE rollout status deploy keycloak-postgresql # Rollout keycloak postgres

    # Install kafka operator
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/kafka-strimzi/crds/kafkaOperator.yaml | sed -e 's|$NAMESPACE|'"$NAMESPACE"'|g' | kubectl -n $NAMESPACE apply -f -
    kubectl -n $NAMESPACE rollout status deploy strimzi-cluster-operator

    # Deploy a kafka cluster
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/kafka/kafka-lb.yaml | kubectl -n $NAMESPACE apply -f -
    # waiting for zookeeper deployment
    waitForResourceCreated pod cno-kafka-cluster-zookeeper-0
    kubectl -n $NAMESPACE wait -l statefulset.kubernetes.io/pod-name=cno-kafka-cluster-zookeeper-0 --for=condition=ready pod --timeout=5m
    # waiting for kafka deployment
    waitForResourceCreated pod cno-kafka-cluster-kafka-0
    kubectl -n $NAMESPACE wait -l statefulset.kubernetes.io/pod-name=cno-kafka-cluster-kafka-0 --for=condition=ready pod --timeout=5m
    # Create cno kafka super-admin user
    kubectl -n $NAMESPACE  apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/kafka/cno-super-admin.yaml
    # Get the kafka brokers lb
    KAFKA_BOOTSTRAP=$(kubectl -n $NAMESPACE get service cno-kafka-cluster-kafka-external-bootstrap -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}')
    KAFKA_BOOTSTRAP_IP=$(kubectl -n $NAMESPACE get service cno-kafka-cluster-kafka-external-bootstrap -o=jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}')
    while true; do                                                                     
        KAFKA_BOOTSTRAP_IP=$(kubectl -n $NAMESPACE get service cno-kafka-cluster-kafka-external-bootstrap -o=jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}')        
        if [[ -z "$KAFKA_BOOTSTRAP_IP" ]]; then                                               
            echo "Waiting for endpoint readiness..."                                   
            sleep 10                                                                   
        else                                                                           
            sleep 2                                                                                                                                          
            break                                                                      
        fi                                                                             
    done
    echo "  The bootstrap load balancer address is $KAFKA_BOOTSTRAP"
    echo "  The bootstrap load balancer is $KAFKA_BOOTSTRAP_IP"

    # Restart keycloak to reload realm cno
    sleep 30s
    kubectl -n $NAMESPACE delete pod keycloak-0
    echo "  waiting recreate keycloak ..."
    kubectl -n $NAMESPACE wait pod keycloak-0 --for=condition=ready --timeout=5m


    # Install Mysql Operator
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/operator/mysql-operator/mysql-operator.yaml | sed -e 's|$NAMESPACE|'"$NAMESPACE"'|g' | kubectl -n $NAMESPACE apply -f -

    # Install Mysql cluster
    MYSQL_PWD=$(openssl rand -base64 14)
    kubectl -n $NAMESPACE create secret generic cno-api-db-secret  --from-literal=ROOT_PASSWORD="${MYSQL_PWD}"
    kubectl -n $NAMESPACE apply -f https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-api/cno-api-mysql.yaml
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
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-api/cno-api.yaml |
        sed 's|$SUPER_ADMIN_PASSWORD|'"$SUPER_ADMIN_PASSWORD"'|g; s|$SERVER_URL|http://keycloak-discovery.'"$NAMESPACE"'.svc.cluster.local:8080|g; s|$OIDC_SERVER_BASE_URL|http://keycloak-discovery.'"$NAMESPACE"'.svc.cluster.local:8080|g; s|$OIDC_REALM|cno|g; s|$OIDC_CLIENT_ID|cno-api|g; s|$KAFKA_BROKERS|cno-kafka-cluster-kafka-bootstrap:9093|g; s|$DEFAULT_EXTERNAL_BROKERS_URL|'"$KAFKA_BOOTSTRAP_IP"'|g; s|$CREATE_DEFAULT_CLUSTER|"'"$INSTALL_DATA_PLANE"'"|g; s|$DEFAULT_CLUSTER_API_SERVER_URL|"'"$DEFAULT_CLUSTER_API_SERVER_URL"'"|g; s|$DEFAULT_CLUSTER_ID|'"$DEFAULT_AGENT_ID"'|g; s|ClusterIP|LoadBalancer|g; s|$NAMESPACE|'"$NAMESPACE"'|g' |
        kubectl -n $NAMESPACE apply -f -
    kubectl -n $NAMESPACE rollout status deploy cno-api
    CNO_API_LB=$(kubectl -n $NAMESPACE get service cno-api -o=jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}')
    # Install CNO NOTIFICATION
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/notification/cno-notification.yaml | sed 's|ClusterIP|NodePort|g'  | kubectl -n $NAMESPACE apply -f -
    CNO_NOTIFICATION_LB=$(kubectl -n $NAMESPACE get service cno-notification -o=jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}')

    # Install CNO UI
    curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/deploy/control-plane/onboarding-ui/cno-ui.yaml |
        sed 's|$API_URL|https://'"$CNO_API_LB"'|g;  s|$NOTIFICATION_URL|https://'"$CNO_NOTIFICATION_LB"'|g; s|$OIDC_URL|http://keycloak-discovery.'"$NAMESPACE"'.svc.cluster.local:8080|g; s|$OIDC_REALM|cno|g; s|$OIDC_CLIENT_ID|public|g; s|ClusterIP|LoadBalancer|g' |
        kubectl -n $NAMESPACE apply -f -
    CNO_UI_LB=$(kubectl -n $NAMESPACE get service cno-ui -o=jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}')
    while true; do                                                                     
        CNO_UI_LB=$(kubectl -n $NAMESPACE get service cno-ui -o=jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}')        
        if [[ -z "$CNO_UI_LB" ]]; then                                               
            echo "Waiting for endpoint readiness..."                                   
            sleep 10                                                                   
        else                                                                           
            sleep 2                                                                                                                                          
            break                                                                      
        fi                                                                             
    done

    if [ "${INSTALL_DATA_PLANE}" = 'true' ]; then
        # deploy cno-data-plane
        export KAFKA_BROKERS="cno-kafka-cluster-kafka-bootstrap:9093"
        waitForResourceCreated secrets $DEFAULT_AGENT_ID
        kubectl -n $NAMESPACE get secret/cno-kafka-cluster-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/cno-ca
        kubectl -n $NAMESPACE get secret/$DEFAULT_AGENT_ID -o jsonpath='{.data.user\.key}' | base64 -d > /tmp/cno-kafka-key
        kubectl -n $NAMESPACE  get secret/$DEFAULT_AGENT_ID -o jsonpath='{.data.user\.crt}' | base64 -d > /tmp/cno-kafka-cert
        kubectl -n $NAMESPACE create secret generic cno-agent-config --from-literal=licence=$DEFAULT_AGENT_ID --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key
        rm -rf /tmp/cno-*
        curl https://raw.githubusercontent.com/beopencloud/cno/$VERSION/scripts/data-plane/install.sh > cnodataplane.sh
        chmod +x cnodataplane.sh
        ./cnodataplane.sh -n $NAMESPACE
        rm -rf cnodataplane.sh
    fi

    echo
    echo "============================================================================================="
    echo "  INFO CNO installation success."
    echo "  You can access CNO at https://$CNO_UI_LB"
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
installCno
