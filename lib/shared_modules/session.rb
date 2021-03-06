require 'json'
require 'openssl'
require 'base64'

module SharedModules
  module Session
    extend ActiveSupport::Concern
    include SharedModules::Encrypt
    include ActionController::Cookies

    included do
      after_action :sync_sso

      def sync_sso
        ck = ENV['SSO_SYNC_COOKIE']
        if ck.present?
          data = session_user.present? ? {
            e: '',
            id: session_user.id,
            uuid: session_user.uuid,
            email: session_user.email,
            name: session_user.full_name
          }.select{|k,v|v} : { e: '' }
          length = [192 - data.to_json.length, 16].max
          data[:e] = SecureRandom.base58(length)
          
          enc = aes data.to_json
          cookies[ck] = {
            value: enc,
            expires: 2.weeks.from_now,
            domain: '.nsw.gov.au',
            secure: true
          }
        end
      rescue => e
        if Rails.env.production?
          Airbrake.notify_sync e
        else
          puts e.message
          puts e.backtrace
        end
      end

      def update_session_user attrs
        update_c_session({user: attrs})
        @session_user = SharedModules::SessionUser.new(c_session[:user])
      end

      def reset_session_user user
        return @session_user = nil unless user.present?
        # This will not be needed any more after dropping devise completely
        my_buyer = user.is_buyer? &&
          BuyerApplication.find_by(user_id: user.id) || nil
        my_seller = user.seller_id &&
          Seller.find_by(id: user.seller_id) || nil

        user_hash = {
          id: user.id,
          email: user.email,
          uuid: user.uuid,
          full_name: user.full_name,
          seller_id: user.seller_id,
          seller_ids: user.seller_ids,
          roles: user.roles.to_a,
          permissions: user.permissions,
          buyer_id: my_buyer&.id,
          seller_status: my_seller&.status.to_s,
          buyer_status: my_buyer&.state.to_s,
        }

        update_c_session({user: user_hash})

        @session_user = SharedModules::SessionUser.new(user_hash)
      end

      def session_user
        if @session_user.nil?
          user_hash = c_session[:user]
          if user_hash.present?
            @session_user = SharedModules::SessionUser.new(user_hash)
          end
        end

        # This will not be needed any more after dropping devise completely
        if current_user&.id != @session_user&.id ||
           current_user&.uuid != @session_user&.uuid ||
           current_user&.email != @session_user&.email ||
           current_user&.seller_id != @session_user&.seller_id ||
           current_user&.seller_ids != @session_user&.seller_ids ||
           current_user&.permissions != @session_user&.permissions
          reset_session_user(current_user)
        end

        @session_user
      end

      def c_session
        @c_session ||= get_c_session
      end

      def update_c_session update_hash
        return unless session.id.present?
        @c_session = get_c_session.deep_merge(update_hash)
        set_c_session @c_session
      end

      def reset_c_session
        redis.del session_key if session.id.present?
      end

      private

      def redis
        Rails.cache.redis
      end

      def session_timeout
        2.weeks.to_i
      end

      def session_key
        'C_SESSION_' + session.id.to_s
      end

      def set_c_session session_hash
        redis.set session_key, session_hash.to_json
        redis.expire session_key, session_timeout
      end

      def get_c_session
        return {} unless session.id.present?
        redis.expire session_key, session_timeout
        redis.get(session_key).yield_self do |value|
          if value.present?
            JSON.parse value, symbolize_names: true
          else
            {}
          end
        end
      end
    end
  end
end
