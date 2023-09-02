DOCKER_PROJECT_NAME=customized-pki

### Make sure the project has been removed by running down -v
docker compose --project-name $DOCKER_PROJECT_NAME down -v

docker compose --project-name $DOCKER_PROJECT_NAME up -d
docker compose --project-name $DOCKER_PROJECT_NAME logs -f &

EXTERNAL_CA_PARENT_CHAIN=/tmp/intermediate.parent-chain.pem
EXTERNAL_CA_KEY=/tmp/intermediate.from.external.ca.key
EXTERNAL_CA_CERT=/tmp/intermediate.from.external.ca.cert
EXTERNAL_DNS=ctrl.home.pi
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

docker run -it --rm --user root \
  --entrypoint "" \
  --network customized-pki_ziti \
  --network-alias ziti-controller \
  --network-alias ${EXTERNAL_DNS} \
  -v customized-pki_ziti-fs:/opt/ziti \
  -v ${SCRIPT_DIR}/compose-from-custom-pki.sh:/tmp/compose-from-custom-pki.sh \
  -v $EXTERNAL_CA_KEY:/tmp/external.key \
  -v $EXTERNAL_CA_CERT:/tmp/external.cert \
  -v $EXTERNAL_CA_PARENT_CHAIN:/tmp/parent-chain.pem \
  --env-file=.env \
  openziti/ziti-controller bash /tmp/compose-from-custom-pki.sh 

docker compose --project-name $DOCKER_PROJECT_NAME up -d