require 'digest'

require 'active_resource'

module SharedResources
  class ApplicationResource < ::ActiveResource::Base
    def self.generate_token(user=nil)
      user_json = if user
        {
          user: {
            id: user.id,
            email: user.email,
            roles: user.roles.to_a,
            seller_id: user.seller_id,
            # FIXME below is disabled as it created a loop
            # buyer_id: user.buyer_id,
            # seller_status: user.seller_status,
            # buyer_status: user.buyer_status
           },
          timestamp: Time.now.to_i
        }
      else
        {
          timestamp: Time.now.to_i
        }
      end
      jwt_token = JWT.encode(user_json, ENV['SERVICE_AUTH_SECRET'], 'HS256')
      self.headers['Authentication'] = "Token #{jwt_token}"
    end

    def self.root_url
      "http#{ENV['EMAIL_URL_PORT'].to_i==443?'s':''}://#{ENV['EMAIL_URL_HOST']}:#{ENV['EMAIL_URL_PORT']}/"
    end
  end
end
