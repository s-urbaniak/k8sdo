#!/bin/bash

set -x

if [ -z $SSH_KEY ]; then
    echo "SSH_KEY must be set"
    exit 1
fi

if [ -z $ETCD_IP ]; then
    echo "ETCD_IP must be set"
    exit 1
fi

DO_REGION="fra1"
ETCD_SIZE="2gb"

sed -e "s|{{ETCD_IP}}|${ETCD_IP}|" user-data-master.tpl >user-data-master

doctl compute droplet create "master-1" \
      --region "${DO_REGION}" \
      --image "coreos-alpha" \
      --size "${ETCD_SIZE}" \
      --enable-private-networking \
      --ssh-keys '"'"${SSH_KEY}"'"' \
      --user-data-file cluster/user-data-master
