require 'digest'

require 'active_resource'

module SharedResources
  class ApplicationResource < ::ActiveResource::Base
    def self.root_url
      "http#{ENV['EMAIL_URL_PORT'].to_i==443?'s':''}://#{ENV['EMAIL_URL_HOST']}:#{ENV['EMAIL_URL_PORT']}/"
    end

    self.site = self.root_url + 'api'
    self.connection.auth_type = :bearer
    self.connection.bearer_token = -> { self.bearer_token }

    def self.generate_token(user=nil)
      @user = user
    end

    protected

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
