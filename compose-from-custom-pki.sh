export ZITI_HOME="/opt/ziti/quickstart"
mkdir -p $ZITI_HOME
cd $ZITI_HOME
export ZITI_HOSTNAME="${EXTERNAL_DNS}"
export ZITI_PKI="${ZITI_HOME}/pki"
export ZITI_CTRL_ADVERTISED_ADDRESS=${ZITI_HOSTNAME}
export ZITI_CTRL_EDGE_ADVERTISED_ADDRESS=${ZITI_HOSTNAME}

EXTERNAL_CA_INTERMEDIATE_NAME="intermediate.from.external.ca"
mkdir -p $ZITI_PKI/$EXTERNAL_CA_INTERMEDIATE_NAME/keys
mkdir -p $ZITI_PKI/$EXTERNAL_CA_INTERMEDIATE_NAME/certs
touch $ZITI_PKI/$EXTERNAL_CA_INTERMEDIATE_NAME/index.txt

cp /tmp/external.key $ZITI_PKI/$EXTERNAL_CA_INTERMEDIATE_NAME/keys/$EXTERNAL_CA_INTERMEDIATE_NAME.key
cp /tmp/external.cert $ZITI_PKI/$EXTERNAL_CA_INTERMEDIATE_NAME/certs/$EXTERNAL_CA_INTERMEDIATE_NAME.cert


### Create three intermediates from the provisioned intermediate CA
ZITI_CTRL_CA_NAME="${ZITI_HOSTNAME}-network-components"
ZITI_EDGE_CA_NAME="${ZITI_HOSTNAME}-edge"
ZITI_SIGN_CA_NAME="${ZITI_HOSTNAME}-identities"

ziti pki create intermediate \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${EXTERNAL_CA_INTERMEDIATE_NAME}" \
  --intermediate-name "${ZITI_CTRL_CA_NAME}" \
  --intermediate-file "${ZITI_CTRL_CA_NAME}" \
  --max-path-len "1"
  
ziti pki create intermediate \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${EXTERNAL_CA_INTERMEDIATE_NAME}" \
  --intermediate-name "${ZITI_EDGE_CA_NAME}" \
  --intermediate-file "${ZITI_EDGE_CA_NAME}" \
  --max-path-len "1"
  
ziti pki create intermediate \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${EXTERNAL_CA_INTERMEDIATE_NAME}" \
  --intermediate-name "${ZITI_SIGN_CA_NAME}" \
  --intermediate-file "${ZITI_SIGN_CA_NAME}" \
  --max-path-len "1"

### Create Server and Client certs for the control plane and the http api
ZITI_NETWORK_COMPONENTS_PKI_NAME="ziti.network.components"
ZITI_NETWORK_COMPONENTS_ADDRESSES="localhost,${ZITI_HOSTNAME},some.other.name,and.another.name"
ZITI_NETWORK_COMPONENTS_IPS="127.0.0.1,127.0.21.71,192.168.100.100"

ziti pki create key \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${ZITI_CTRL_CA_NAME}" \
  --key-file "${ZITI_NETWORK_COMPONENTS_PKI_NAME}"

ziti pki create server \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${ZITI_CTRL_CA_NAME}" \
  --key-file "${ZITI_NETWORK_COMPONENTS_PKI_NAME}" \
  --server-file "${ZITI_NETWORK_COMPONENTS_PKI_NAME}-server" \
  --server-name "${ZITI_NETWORK_COMPONENTS_PKI_NAME}-server" \
  --dns "${ZITI_NETWORK_COMPONENTS_ADDRESSES}" \
  --ip "${ZITI_NETWORK_COMPONENTS_IPS}"

ziti pki create client \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${ZITI_CTRL_CA_NAME}" \
  --key-file "${ZITI_NETWORK_COMPONENTS_PKI_NAME}" \
  --client-file "${ZITI_NETWORK_COMPONENTS_PKI_NAME}-client" \
  --client-name "${ZITI_NETWORK_COMPONENTS_PKI_NAME}"

ZITI_EDGE_API_PKI_NAME="ziti.edge.controller"
ZITI_EDGE_API_ADDRESSES="${ZITI_NETWORK_COMPONENTS_ADDRESSES}"
ZITI_EDGE_API_IPS="${ZITI_NETWORK_COMPONENTS_IPS}"

ziti pki create key \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${ZITI_EDGE_CA_NAME}" \
  --key-file "${ZITI_EDGE_API_PKI_NAME}"
  
ziti pki create server \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${ZITI_EDGE_CA_NAME}" \
  --key-file "${ZITI_EDGE_API_PKI_NAME}" \
  --server-file "${ZITI_EDGE_API_PKI_NAME}-server" \
  --server-name "${ZITI_EDGE_API_PKI_NAME}-server" \
  --dns "${ZITI_EDGE_API_ADDRESSES}" \
  --ip "${ZITI_EDGE_API_IPS}"

ziti pki create client \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${ZITI_EDGE_CA_NAME}" \
  --key-file "${ZITI_EDGE_API_PKI_NAME}" \
  --client-file "${ZITI_EDGE_API_PKI_NAME}-client" \
  --client-name "${ZITI_EDGE_API_PKI_NAME}"

### Emit an OpenZiti Controller Config file
#### Set env vars for the create config to function as expected
export ZITI_PKI_CTRL_KEY="${ZITI_PKI}/${ZITI_CTRL_CA_NAME}/keys/${ZITI_NETWORK_COMPONENTS_PKI_NAME}.key"
export ZITI_PKI_CTRL_SERVER_CERT="${ZITI_PKI}/${ZITI_CTRL_CA_NAME}/certs/${ZITI_NETWORK_COMPONENTS_PKI_NAME}-server.chain.pem"
export ZITI_PKI_CTRL_CERT="${ZITI_PKI}/${ZITI_CTRL_CA_NAME}/certs/${ZITI_NETWORK_COMPONENTS_PKI_NAME}-client.cert"
export ZITI_PKI_CTRL_CA="${ZITI_PKI}/${ZITI_CTRL_CA_NAME}/cas.pem"

export ZITI_PKI_EDGE_KEY="${ZITI_PKI}/${ZITI_EDGE_CA_NAME}/keys/${ZITI_EDGE_API_PKI_NAME}.key"
export ZITI_PKI_EDGE_SERVER_CERT="${ZITI_PKI}/${ZITI_EDGE_CA_NAME}/certs/${ZITI_EDGE_API_PKI_NAME}-server.chain.pem"
export ZITI_PKI_EDGE_CERT="${ZITI_PKI}/${ZITI_EDGE_CA_NAME}/certs/${ZITI_EDGE_API_PKI_NAME}-client.cert"
export ZITI_PKI_EDGE_CA="${ZITI_PKI}/${ZITI_EDGE_CA_NAME}/edge.cas.pem"

ZITI_PKI_SIGNER_NAME="-signer"
export ZITI_PKI_SIGNER_KEY="${ZITI_PKI}/${ZITI_SIGN_CA_NAME}/keys/${ZITI_SIGN_CA_NAME}.key"
export ZITI_PKI_SIGNER_CERT="${ZITI_PKI}/${ZITI_SIGN_CA_NAME}/certs/${ZITI_SIGN_CA_NAME}.chain.pem"

ziti create config controller >${ZITI_HOME}/${ZITI_HOSTNAME}.yaml


cat /tmp/parent-chain.pem > ${ZITI_PKI_CTRL_CA}
cat /tmp/parent-chain.pem > ${ZITI_PKI_EDGE_CA}
mkdir ${ZITI_HOME}/db
ziti controller edge init "${ZITI_HOME}/${ZITI_HOSTNAME}.yaml" -u "admin" -p $ZITI_PWD

ziti controller run ${ZITI_HOME}/${ZITI_HOSTNAME}.yaml &> ${ZITI_HOME}/${ZITI_HOSTNAME}.log &

while [[ "$(curl -w "%{http_code}" -m 1 -s -k -o /dev/null https://localhost:${ZITI_CTRL_EDGE_ADVERTISED_PORT}/edge/client/v1/version)" != "200" ]]; do
  echo "waiting for https://localhost:${ZITI_CTRL_EDGE_ADVERTISED_PORT}"
  sleep 1
done

ziti edge login localhost:${ZITI_CTRL_EDGE_ADVERTISED_PORT} -u admin -p $ZITI_PWD -y


export ZITI_ROUTER_ADVERTISED_ADDRESS=${ZITI_HOSTNAME}
export ZITI_ROUTER_ADVERTISED_HOST="${ZITI_ROUTER_ADVERTISED_ADDRESS}"

ziti edge delete edge-router ${ZITI_HOSTNAME}-edge-router
ziti edge create edge-router ${ZITI_HOSTNAME}-edge-router -o ${ZITI_HOME}/${ZITI_HOSTNAME}-edge-router.jwt -t -a public
ziti create config router edge --routerName ${ZITI_HOSTNAME}-edge-router >${ZITI_HOME}/${ZITI_HOSTNAME}-edge-router.yaml
ziti router enroll ${ZITI_HOME}/${ZITI_HOSTNAME}-edge-router.yaml --jwt ${ZITI_HOME}/${ZITI_HOSTNAME}-edge-router.jwt

chown -R 2171:2171 /opt/ziti/quickstart/
