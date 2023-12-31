export ZITI_HOME=$PWD
export ZITI_PWD=admin2
export ZITI_HOSTNAME="ctrl.home.pi"
export ZITI_PKI="${ZITI_HOME}/pki"
export ZITI_CTRL_ADVERTISED_ADDRESS="${ZITI_HOSTNAME}"
export ZITI_CTRL_EDGE_ADVERTISED_ADDRESS="${ZITI_HOSTNAME}"
export ZITI_ROUTER_ADVERTISED_ADDRESS="${ZITI_HOSTNAME}"
export ZITI_ROOT_CA_NAME="my.root.ca"
export ZITI_EXTERNAL_CA_INTERMEDIATE_NAME="intermediate.from.external.ca"
export ZITI_CTRL_CA_NAME="${ZITI_HOSTNAME}-network-components"
export ZITI_EDGE_CA_NAME="${ZITI_HOSTNAME}-edge"
export ZITI_SIGN_CA_NAME="${ZITI_HOSTNAME}-identities"
export ZITI_CTRL_ADVERTISED_PORT=8440
export ZITI_CTRL_EDGE_ADVERTISED_PORT=8441
export ZITI_ROUTER_PORT=8442


ziti pki create ca \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${ZITI_ROOT_CA_NAME}" \
  --ca-file "${ZITI_ROOT_CA_NAME}"
  
ziti pki create intermediate \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${ZITI_ROOT_CA_NAME}" \
  --intermediate-name "${ZITI_EXTERNAL_CA_INTERMEDIATE_NAME}" \
  --intermediate-file "${ZITI_EXTERNAL_CA_INTERMEDIATE_NAME}" \
  --max-path-len "2"

ziti pki create intermediate \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${ZITI_EXTERNAL_CA_INTERMEDIATE_NAME}" \
  --intermediate-name "${ZITI_CTRL_CA_NAME}" \
  --intermediate-file "${ZITI_CTRL_CA_NAME}" \
  --max-path-len "1"
  
ziti pki create intermediate \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${ZITI_EXTERNAL_CA_INTERMEDIATE_NAME}" \
  --intermediate-name "${ZITI_EDGE_CA_NAME}" \
  --intermediate-file "${ZITI_EDGE_CA_NAME}" \
  --max-path-len "1"
  
ziti pki create intermediate \
  --pki-root="${ZITI_PKI}" \
  --ca-name "${ZITI_EXTERNAL_CA_INTERMEDIATE_NAME}" \
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


cat "${ZITI_PKI}/my.root.ca/certs/my.root.ca.cert" > "${ZITI_PKI}/${ZITI_HOSTNAME}-network-components/cas.pem"
cat "${ZITI_PKI}/my.root.ca/certs/intermediate.from.external.ca.cert" >> "${ZITI_PKI}/${ZITI_HOSTNAME}-network-components/cas.pem"
cp "${ZITI_PKI}/${ZITI_HOSTNAME}-network-components/cas.pem" "${ZITI_PKI}/${ZITI_HOSTNAME}-edge/edge.cas.pem"
mkdir ${ZITI_HOME}/db
ziti controller edge init "${ZITI_HOME}/${ZITI_HOSTNAME}.yaml" -u "admin" -p $ZITI_PWD

ziti controller run ${ZITI_HOME}/${ZITI_HOSTNAME}.yaml &> ${ZITI_HOME}/${ZITI_HOSTNAME}.log &

while [[ "$(curl -w "%{http_code}" -m 1 -s -k -o /dev/null https://${ZITI_CTRL_ADVERTISED_ADDRESS}:${ZITI_CTRL_EDGE_ADVERTISED_PORT}/edge/client/v1/version)" != "200" ]]; do
  echo "waiting for https://${ZITI_CTRL_ADVERTISED_ADDRESS}:${ZITI_CTRL_EDGE_ADVERTISED_PORT}"
  sleep 1
done

ziti edge login ${ZITI_CTRL_ADVERTISED_ADDRESS}:${ZITI_CTRL_EDGE_ADVERTISED_PORT} -u admin -p $ZITI_PWD -y


export ZITI_ROUTER_ADVERTISED_ADDRESS=${ZITI_HOSTNAME}
export ZITI_ROUTER_ADVERTISED_HOST="${ZITI_ROUTER_ADVERTISED_ADDRESS}"

ziti edge delete edge-router ${ZITI_HOSTNAME}-edge-router
ziti edge create edge-router ${ZITI_HOSTNAME}-edge-router -o ${ZITI_HOME}/${ZITI_HOSTNAME}-edge-router.jwt -t -a public
ziti create config router edge --routerName ${ZITI_HOSTNAME}-edge-router >${ZITI_HOME}/${ZITI_HOSTNAME}-edge-router.yaml
ziti router enroll ${ZITI_HOME}/${ZITI_HOSTNAME}-edge-router.yaml --jwt ${ZITI_HOME}/${ZITI_HOSTNAME}-edge-router.jwt



chown -R 2171:2171 /opt/ziti/quickstart/




