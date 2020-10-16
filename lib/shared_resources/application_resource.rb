require 'digest'

require 'active_resource'

module SharedResources
  class ApplicationResource < ::ActiveResource::Base
    def self.generate_token user
      @user = user
    end

    protected

    def self.root_url
      port_str = ENV['EMAIL_URL_PORT'].to_i.in?([80,443]) ? '' : ( ':' + ENV['EMAIL_URL_PORT'].to_s )
      "http#{ENV['EMAIL_URL_PORT'].to_i==443?'s':''}://#{ENV['EMAIL_URL_HOST']}#{port_str}/"
    end

    def self.bearer_token
      user = @user
      user_json = if user
        {
          user: {
            id: user.id,
            email: user.email,
            roles: user.roles.to_a,
            seller_id: user.seller_id,
            seller_ids: user.seller_ids,
            permissions: user.permissions,
            # FIXME below is disabled as it created a loop
            # buyer_id: user.buyer_id,
            # seller_status: user.seller_status,
            # buyer_status: user.buyer_status
          },
          timestamp: Time.now.to_i,
          nonce: SecureRandom.base58(10),
        }
      else
        {
          timestamp: Time.now.to_i,
          nonce: SecureRandom.base58(10),
        }
      end
      @user = nil
      JWT.encode(user_json, ENV['SERVICE_AUTH_SECRET'], 'HS256')
    end
  end
end
