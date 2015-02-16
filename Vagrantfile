# -*- mode: ruby -*-
# vi: set ft=ruby :

# This file is based on https://github.com/coreos/coreos-vagrant/blob/master/Vagrantfile

require_relative 'config'
require_relative 'do_config'
include CoreosVagrant::Config
include CoreosVagrant::DigitalOceanConfig

CoreosVagrant::Config.load('config/cluster.yml', '.secrets/digital_ocean.yml')

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

if ARGV[0].eql?('up') && ARGV.count == 1
  File.delete discovery_token_filename if File.exists? discovery_token_filename
end

Vagrant.configure('2') do |config|
  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  num_nodes.times.map { |i| host_name_pattern % i }.each_with_index do |node_name, index|
    config.vm.define node_name do |node|
      node.ssh.username = username
      node.ssh.insert_key = false

      nfs_mountpoints.each do |mp|
        dirs = mp['mapping'].split(':')
        if dirs.size == 2
          node.vm.synced_folder(
            dirs[0], dirs[1],
            id: mp['id'],
            nfs: true,
            mount_options: [mp['options']]
          )
        else
          puts "Invalid nfs mapping #{mp['mapping']}: must have format <local dir>:<mount dir>"
        end
      end

      node.vm.provider :virtualbox do |provider, override|
        provider.check_guest_additions = false
        provider.functional_vboxsf     = false

        provider.name = node_name
        provider.memory = memory
        provider.cpus = cpus

        override.vm.network :private_network, ip: private_subnet % (start_ip+index)

        override.vm.hostname = node_name
        # Vagrant needs to boot using its insecure private key
        override.ssh.private_key_path = ["#{ENV['HOME']}/.vagrant.d/insecure_private_key" ] + ssh_keys

        override.vm.box = 'coreos-%s' % coreos_update_channel
        override.vm.box_version = coreos_box_version
        override.vm.box_url = 'http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json' % coreos_update_channel

        # The user-data file must be moved atomically to /var/lib/coreos-vagrant/vagrantfile-user-data
        # (https://github.com/YungSang/coreos-cluster/issues/2 hints at the issue)
        override.vm.provision :shell, inline: "echo '#{user_data(node_name)}' > /tmp/vagrantfile-user-data"
        override.vm.provision :shell, privileged: true, inline: "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/vagrantfile-user-data"
      end

      node.vm.provider :digital_ocean do |provider, override|
        provider.name = node_name
        provider.size = "#{memory/1024}GB"
        provider.token = do_access_token
        provider.image = 'coreos-stable'
        provider.ipv6 = false
        provider.private_networking = true
        provider.region = 'nyc3'
        provider.user_data = user_data(node_name)

        # This should be set to false, otherwise backups are turned on (v0.7.1)
        provider.backups_enabled = false

        # There's a bug in the digital_ocean provider (v0.7.1) which causes vagrant up to hang unless this is false
        provider.setup = false

        override.ssh.username = username

        override.ssh.private_key_path = ssh_keys

        override.vm.box = 'digital_ocean'
        override.vm.box_url = 'https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box'
      end
    end
  end
end
