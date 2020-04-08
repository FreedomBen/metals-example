#!/usr/bin/env bash

# shellcheck disable=1091
if [ -f common.sh ]; then
  . common.sh
elif [ -f scripts/common.sh ]; then
  . scripts/common.sh
else
  echo "Couldn't find common.sh.  Run from root dir or scripts dir"
fi

  #--env VAULT_ROLE=UJ10 \
  #--env VAULT_KUBERNETES_AUTH_PATH=a/long/thing \
echo "Starting mtls..."
$PODMAN run \
  --detach \
  --user 12345 \
  \
  --env METALS_SSL=on \
  --env METALS_SSL_VERIFY_CLIENT=on \
  --env METALS_DEBUG=true \
  --env VAULT_ADDR=http://localhost:8200 \
  --env VAULT_ROOT_PATH=v1/secret/data \
  --env VAULT_TOKEN="$VAULT_TOKEN" \
  \
  --env METALS_PROXY_PASS_PROTOCOL=http \
  --env METALS_PROXY_PASS_HOST=127.0.0.1 \
  --env METALS_FORWARD_PORT=8080 \
  \
  --env METALS_PUBLIC_CERT_VAULT_KEY=crt \
  --env METALS_PUBLIC_CERT_VAULT_PATH=mtls/script/server \
  \
  --env METALS_PRIVATE_KEY_VAULT_KEY=key \
  --env METALS_PRIVATE_KEY_VAULT_PATH=mtls/script/server \
  \
  --env METALS_SERVER_CHAIN_VAULT_KEY=server \
  --env METALS_SERVER_CHAIN_VAULT_PATH=mtls/script/trust-chain \
  \
  --env METALS_CLIENT_CHAIN_VAULT_KEY=client \
  --env METALS_CLIENT_CHAIN_VAULT_PATH=mtls/script/trust-chain  \
  \
  --env METALS_HEALTH_CHECK_PATH=/health \
  \
  --name "$METALS_CONTAINER" \
  --pod "$PODNAME" \
  "$METALS_IMAGE"
echo "Done starting mtls"
