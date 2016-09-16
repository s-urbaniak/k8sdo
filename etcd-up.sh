#!/bin/bash

set -x

if [ -z $SSH_KEY ]; then
    echo "SSH_KEY must be set"
    exit 1
fi

set -e

# see https://developers.digitalocean.com/documentation/v2/#regions
DO_REGION=fra1

# etcd instance count
ETCD_COUNT=1

# see https://developers.digitalocean.com/documentation/v2/#sizes
ETCD_SIZE="512mb"

DISCOVERY_URL=$(curl https://discovery.etcd.io/new?size=${ETCD_COUNT})

sed -e "s|{{DISCOVERY_URL}}|${DISCOVERY_URL}|" user-data-etcd.tpl >user-data-etcd

for CNT in $(seq 1 $ETCD_COUNT); do
    doctl compute droplet create "etcd-${CNT}" \
          --region "${DO_REGION}" \
          --image "coreos-alpha" \
          --size "${ETCD_SIZE}" \
          --enable-private-networking \
          --ssh-keys '"'"${SSH_KEY}"'"' \
          --user-data-file user-data-etcd
done
