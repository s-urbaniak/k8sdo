## DigitalOcean Quickstart

### Set up Digital Ocean API token

Set up a read/write API token in Digital Ocean. Install doctl [1], and initialize the API token:
```
$ doctl auth init
```

Export your SSH fingerprint:

```
$ ssh-keygen -E md5 -l -f ~/.ssh/id_rsa.pub
2048 MD5:xx:xx:xx:xx:xx:xx:xx:xx:xx:ab:19:db:52:cb:08:97 no comment (RSA)
$ export SSH_KEY="xx:xx:xx:xx:xx:xx:xx:xx:xx:ab:19:db:52:cb:08:97"
```

### Launch etcd

```
$ ./etcd-up.sh
```

Get the internal IP address of the etcd instance:

```
$ doctl compute droplet list
$ export ETCD_IP=$(doctl compute droplet get 25997786 -o json | jq -r -c '.[].networks.v4[] | select(.type=="private").ip_address')
```

Create a new Droplet, a bigger master machine:
```
$ ./master-up.sh
```

Render k8s manifests, and start bootkube
```
$ doctl compute droplet list
ID		Name		Public IPv4	Public IPv6	Memory	VCPUs	Disk	Region	Image			Status	Tags
25985490	etcd-1		188.166.163.26			512	1	20	fra1	CoreOS 1164.1.0 (alpha)active	
25990476	master-1	138.68.75.149			2048	2	40	fra1	CoreOS 1164.1.0 (alpha)active	

$ doctl compute ssh 25990476 --ssh-user core

$ export ETCD_IP=10.135.20.79

$ sudo rkt run quay.io/coreos/bootkube:v0.1.4 \
    --insecure-options=image \
    --volume=core,kind=host,source=/home/core \
    --mount volume=core,target=/core \
    --net=none \
    --exec=/bootkube \
    -- render \
    --asset-dir=/core/cluster \
    --api-servers=https://${COREOS_PUBLIC_IPV4}:443 \
    --etcd-servers=http://${ETCD_IP}:2379

$ sudo chown -R core:core cluster
$ sudo mkdir -p /etc/kubernetes
$ sudo cp cluster/auth/kubeconfig /etc/kubernetes/kubeconfig

$ sudo rkt run quay.io/coreos/bootkube:v0.1.4 \
    --insecure-options=all \
    --volume=core,kind=host,source=/home/core \
    --mount volume=core,target=/core \
    --net=host \
    --exec=/bootkube \
    -- start \
    --asset-dir=/core/cluster \
    --etcd-server=http://${ETCD_IP}:2379
```

In another terminal start kubelet
```
$ sudo systemctl start kubelet
```

Configure client
```
$ export MASTER_IP=46.101.244.90

$ scp -r core@${MASTER_IP}:~/cluster .

$ kubectl config set-cluster do \
    --server=https://${MASTER_IP}:443

$ kubectl config set-credentials do \
    --client-certificate=cluster/tls/apiserver.crt \
    --client-key=cluster/tls/apiserver.key

$ kubectl config set-context do --cluster=do --user=do

$ kubectl config use-context do
```

[1] https://github.com/digitalocean/doctl
