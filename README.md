# Bring up a CoreOS cluster on Virtualbox or Digital Ocean

This project can be used to spin up a CoreOS cluster on VirtualBox or Digital Ocean, using Vagrant.

It was inspired by [https://github.com/coreos/coreos-vagrant](http://).

### Usage

#### Virtualbox

To start the cluster on Virtualbox:

    $ vagrant up --provider virtualbox

Note that if you've configured NFS shares, you'll need to have `nfsd` running on your host, and you may be prompted for your system password when the cluster nodes try to mount the shares.

#### Digital Ocean

The digital ocean provider and vagrant box used are courtesy of Shawn Dahlen ([https://github.com/smdahlen/vagrant-digitalocean](https://)).

To start the cluster on Digital Ocean, you'll need to configure your access token in `.secrets/digital_ocean.yml`:

    digital_ocean:
      access_token: your-access-token

Then,

    $ vagrant plugin install vagrant-digitalocean
    $ vagrant up --provider digital_ocean

#### Verifying that the cluster is running

    $ vagrant ssh box-0 -- -A
    CoreOS beta (557.2.0)
	core@box-0 ~ $ fleetctl list-machines
    MACHINE		IP		METADATA
    1f88cc48...	10.100.100.102	-
    a63d25ad...	10.100.100.101	-
    f10c9ccb...	10.100.100.100	-

### Cluster Configuration

The cluster configuration file is `config/cluster.yml`.  Most settings are hopefully self-explanatory, perhaps with the exception of the discovery token (for additional info on cluster discovery, see [https://coreos.com/docs/cluster-management/setup/cluster-discovery/](htp://).

*WARNING*: Starting up the cluster using `vagrant up` (with no other arguments) will remove the `.discovery_token` file and create a new one.  Keep this mind when bringing your cluster and/or individual nodes up and down.

```
version:
  coreos_update_channel: beta
  coreos_box_version: '>= 522.5.0'

cluster:
  num_nodes: 3
  memory: 1024
  cpus: 1
  private_subnet: 10.100.100.%d
  start_ip: 100
  host_name_pattern: box-%d
  username: core
  user_data_filename: user-data

discovery:
  token_filename: .discovery_token

ssh_keys: <%="#{ENV['HOME']}/.ssh/id_rsa"%> # replace with your own filename, if different

nfs:
  - id: share
    mapping: ..:/home/core/share
    options: nolock,vers=3,udp
```

### CoreOS Customization via Cloud-Config

The file `user-data` contains a cloud-config template which is used to configure the essential OS services, namely `etcd`, `fleet` and `docker`.  Additional services that should be started on each cluster node can be added to this file.

```
#cloud-config

---
coreos:
  etcd:
    discovery: <replaced at runtime>
    addr: $private_ipv4:4001
    peer-addr: $private_ipv4:7001
  fleet:
    public-ip: $private_ipv4
  units:
  - name: etcd.service
    command: start
  - name: fleet.service
    command: start
  - name: docker-tcp.socket
    command: start
    enable: true
    content: |
      [Unit]
      Description=Docker Socket for the API

      [Socket]
      ListenStream=2375
      Service=docker.service
      BindIPv6Only=both

      [Install]
      WantedBy=sockets.target
  - name: docker.service
    commmand: restart
```


### License

This project is released under the [MIT License][mit].

[mit]: http://www.opensource.org/licenses/MIT
