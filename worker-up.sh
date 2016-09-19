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

if [ -z $MASTER_IP ]; then
    echo "MASTER_IP must be set"
    exit 1
fi

DO_REGION="fra1"
WORKER_COUNT=1
WORKER_SIZE="2gb"

cat user-data-worker.tpl > user-data-worker && sed 's/^/      /' cluster/auth/kubeconfig >> user-data-worker

sed -i \
    -e "s|{{ETCD_IP}}|${ETCD_IP}|" \
    -e "s|{{MASTER_IP}}|${MASTER_IP}|" \
    user-data-worker

for CNT in $(seq 1 $WORKER_COUNT); do
    doctl compute droplet create "worker-${CNT}" \
          --region "${DO_REGION}" \
          --image "coreos-alpha" \
          --size "${WORKER_SIZE}" \
          --enable-private-networking \
          --ssh-keys '"'"${SSH_KEY}"'"' \
          --user-data-file user-data-worker
done
