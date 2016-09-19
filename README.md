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

Create master node:
```
$ ./master-up.sh
```

Create worker node:
```
$ doctl compute droplet list
ID		Name		Public IPv4	Public IPv6	Memory	VCPUs	Disk	Region	Image			Status	Tags
25985490	etcd-1		188.166.163.26			512	1	20	fra1	CoreOS 1164.1.0 (alpha)active	
25990476	master-1	138.68.75.149			2048	2	40	fra1	CoreOS 1164.1.0 (alpha)active	

$ export MASTER_IP=46.101.244.90
$ ./worker-up.sh
```

Configure client:
```
$ scp -r core@${MASTER_IP}:~/cluster .

$ kubectl config set-cluster do \
    --insecure-skip-tls-verify=true \
    --server=https://${MASTER_IP}:443

$ kubectl config set-credentials do \
    --client-certificate=cluster/tls/apiserver.crt \
    --client-key=cluster/tls/apiserver.key

$ kubectl config set-context do --cluster=do --user=do
$ kubectl config use-context do
```

[1] https://github.com/digitalocean/doctl
