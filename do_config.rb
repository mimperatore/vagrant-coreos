module CoreosVagrant
  module DigitalOceanConfig
    extend Config

    def do_access_token
      config['digital_ocean']['access_token']
    end
  end
end
