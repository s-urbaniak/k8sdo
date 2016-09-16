## DigitalOcean Quickstart

### Set up Digital Ocean API token

Set up a read/write API token in Digital Ocean. Install doctl [1], and initialize the API token:
```
$ doctl auth init
```

### Launch etcd

```
$ ./etcd-up.sh
```

Get the internal IP address of the etcd instance:

```
$ doctl compute droplet list
$ doctl compute droplet get "${ETCD_1_ID}" -o json | jq -r -c '.[].networks.v4[] | select(.type=="private").ip_address'
10.135.20.79
```

Create a new Droplet, a bigger master machine:
```
$ ./master-up.sh
```

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
    --api-servers=https://${COREOS_PUBLIC_IP}:443 \
    --etcd-servers=http://${ETCD_IP}:2379
$ chmod ...
$ cp cluster/auth/kubeconf /etc/kubernetes/kubeconf
```

```
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

[1] https://github.com/digitalocean/doctl
