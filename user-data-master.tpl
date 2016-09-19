#cloud-config

coreos:
  update:
    reboot-strategy: "off"

  flannel:
    interface: $public_ipv4
    etcd_endpoints: http://{{ETCD_IP}}:2379

  units:
    - name: flanneld.service
      command: start
      drop-ins:
      - name: 50-network-config.conf
        content: |
          [Service]
          ExecStartPre=/usr/bin/etcdctl --endpoint=http://{{ETCD_IP}}:2379 set /coreos.com/network/config '{ "Network": "10.2.0.0/16" }'

    - name: kubelet.service
      enable: true
      content: |
        [Unit]
        After=flanneld.service
        Requires=flanneld.service

        [Service]
        EnvironmentFile=/etc/environment
        Environment=KUBELET_ACI=quay.io/coreos/hyperkube
        Environment=KUBELET_VERSION=v1.3.6_coreos.0

        ExecStartPre=/bin/mkdir -p /etc/kubernetes/manifests
        ExecStartPre=/bin/mkdir -p /srv/kubernetes/manifests
        ExecStartPre=/bin/mkdir -p /etc/kubernetes/checkpoint-secrets

        ExecStart=/usr/lib/coreos/kubelet-wrapper \
          --api-servers=https://$public_ipv4:443 \
          --kubeconfig=/etc/kubernetes/kubeconfig \
          --lock-file=/var/run/lock/kubelet.lock \
          --exit-on-lock-contention \
          --config=/etc/kubernetes/manifests \
          --allow-privileged \
          --hostname-override=$public_ipv4 \
          --address=$private_ipv4 \
          --node-labels=master=true \
          --minimum-container-ttl-duration=3m0s \
          --cluster_dns=10.3.0.10 \
          --cluster_domain=cluster.local

        Restart=always
        RestartSec=5

        [Install]
        WantedBy=multi-user.target

    - name: bootkube-render.service
      content: |
        [Service]
        Type=oneshot

        ExecStartPre=/bin/mkdir -p /etc/kubernetes

        ExecStart=/usr/bin/rkt run quay.io/coreos/bootkube:v0.1.4 \
          --user=500 \
          --group=500 \
          --insecure-options=image \
          --volume=core,kind=host,source=/home/core \
          --mount volume=core,target=/core \
          --net=none \
          --exec=/bootkube \
          -- render \
          --asset-dir=/core/cluster \
          --api-servers=https://$public_ipv4:443 \
          --etcd-servers=http://{{ETCD_IP}}:2379

        ExecStart=/bin/cp /home/core/cluster/auth/kubeconfig /etc/kubernetes/kubeconfig

    - name: bootkube.service
      command: start
      content: |
        [Unit]
        Requires=bootkube-render.service kubelet.service
        After=bootkube-render.service

        [Service]
        Type=oneshot

        ExecStartPre=/bin/mkdir -p /etc/kubernetes
        ExecStart=/usr/bin/rkt run quay.io/coreos/bootkube:v0.1.4 \
          --insecure-options=all \
          --volume=core,kind=host,source=/home/core \
          --mount volume=core,target=/core \
          --net=host \
          --exec=/bootkube \
          -- start \
          --asset-dir=/core/cluster \
          --etcd-server=http://{{ETCD_IP}}:2379
