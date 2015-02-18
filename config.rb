require 'yaml'
require 'erb'

module CoreosVagrant
  module Config
    def self.load(*files)
      files.each do |f|
        config.merge! YAML.load(ERB.new(File.read(f)).result) if File.exist? f
      end
    end

    def config
      @@config ||= {}
    end

    def num_nodes
      config['cluster']['num_nodes']
    end

    def memory
      config['cluster']['memory']
    end

    def cpus
      config['cluster']['cpus']
    end

    def private_subnet
      config['cluster']['private_subnet']
    end

    def start_ip
      config['cluster']['start_ip']
    end

    def host_name_pattern
      config['cluster']['host_name_pattern']
    end

    def username
      config['cluster']['username']
    end

    def coreos_update_channel
      config['version']['coreos_update_channel']
    end

    def coreos_box_version
      config['version']['coreos_box_version']
    end

    def discovery_token_filename
      config['discovery']['token_filename']
    end

    def discovery_token
      require 'open-uri'
      if File.exists?(discovery_token_filename)
        token = File.read(discovery_token_filename)
      else
        token = open('https://discovery.etcd.io/new').read
        File.open(discovery_token_filename, 'w') { |file| file.write(token) }
        token
      end
    end

    def user_data_filename
      config['cluster']['user_data_filename']
    end

    def user_data(node_name)
      require 'yaml'
      data = YAML.load_file(user_data_filename)
      data['coreos']['etcd']['discovery'] = discovery_token
      yaml = "#{YAML.dump(data).gsub('"', '\\\"')}#{ssh_authorized_keys}"
      "#cloud-config\n\n#{yaml}"
    end

    def ssh_authorized_keys
      "ssh_authorized_keys:\n" +
      ssh_keys.map do |private_key_filename|
        "  - #{File.read("#{private_key_filename}.pub")}"
      end.join('\n') unless ssh_keys.empty?
    end

    def ssh_keys
      [config['ssh_keys']].flatten.compact
    end

    # nfsd needs to be running on the host machine in order to mount nfs shares
    def nfs_mountpoints
      config['nfs'] || []
    end
  end
end

