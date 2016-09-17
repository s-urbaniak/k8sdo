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

    - name: rkt-api.service
      enable: true
      command: start
      content: |
        [Unit]
        Description=rkt api service
        After=network.target

        [Service]
        ExecStart=/usr/bin/rkt api-service --listen=127.0.0.1:15441

        [Install]
        WantedBy=multi-user.target

    - name: kubelet.service
      enable: true
      content: |
        [Service]
        After=flanneld
        Requires=flanneld

        EnvironmentFile=/etc/environment
        Environment=KUBELET_ACI=quay.io/coreos/hyperkube
        Environment=KUBELET_VERSION=v1.3.6_coreos.0

        ExecStartPre=/bin/mkdir -p /etc/kubernetes/manifests
        ExecStartPre=/bin/mkdir -p /srv/kubernetes/manifests
        ExecStartPre=/bin/mkdir -p /etc/kubernetes/checkpoint-secrets

        ExecStart=/usr/lib/coreos/kubelet-wrapper \
          --api-servers=https://${COREOS_PUBLIC_IPV4}:443 \
          --kubeconfig=/etc/kubernetes/kubeconfig \
          --lock-file=/var/run/lock/kubelet.lock \
          --exit-on-lock-contention \
          --config=/etc/kubernetes/manifests \
          --allow-privileged \
          --hostname-override=${COREOS_PUBLIC_IPV4} \
          --node-labels=master=true \
          --minimum-container-ttl-duration=3m0s \
          --cluster_dns=10.3.0.10 \
          --cluster_domain=cluster.local

        Restart=always
        RestartSec=5

        [Install]
        WantedBy=multi-user.target
