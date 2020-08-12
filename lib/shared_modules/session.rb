require "json"

module SharedModules
  module Session
    def update_session_user attrs
      update_concurrent_session({user: attrs})
      @session_user = SharedModules::SessionUser.new(user_hash)
    end

    def reset_session_user user
      my_buyer = user.is_buyer? &&
        SharedResources::RemoteBuyer.my_buyer(user) || nil
      my_seller = user.seller_id &&
        SharedResources::RemoteSeller.find(user.seller_id) || nil

      user_hash = {
        id: user.id,
        email: user.email,
        full_name: user.full_name,
        seller_id: user.seller_id,
        roles: user.roles.to_a,
        buyer_id: my_buyer&.id,
        seller_status: my_seller&.status,
        buyer_status: my_buyer&.state,
      }

      update_concurrent_session({user: user_hash})

      @session_user = SharedModules::SessionUser.new(user_hash)
    end

    def session_user
      if @session_user.nil?
        user_hash = concurrent_session[:user]
        if user_hash.present?
          @session_user = SharedModules::SessionUser.new(user_hash)
        end
      end

      # FIXME The following is added to fix a bug and report every time it heppenes.
      # it happens more often when admin impersonates, as it doesn't reset_session_user
      # by adding the concurrent session, other cases shouldn't happen any more!
      # remove this check when the Airbrake erorr is gone
      if current_user&.id != @session_user&.id
        reset_session_user(current_user)
        if Rails.env.production?
          Airbrake.notify_sync StandardError.new('Session user is out of sync again!')
        end
      end

      @session_user
    end

    def redis
      Rails.cache.redis
    end

    def session_timeout
      2.weeks.to_i
    end

    def session_key
      'CONCURRENT_SESSION_' + session.id.to_s
    end

    def concurrent_session
      @concurrent_session ||= get_concurrent_session
    end

    def update_concurrent_session update_hash
      return unless session.id.present?
      @concurrent_session = get_concurrent_session.deep_merge(update_hash)
      redis.set session_key, @concurrent_session.to_json
      redis.expire session_key, session_timeout
    end

    private

    def get_concurrent_session
      return {} unless session.id.present?
      redis.expire session_key, session_timeout
      redis.get(session_key).yield_self do |value|
        if value
          JSON.parse value, symbolize_names: true
        else
          {}
        end
      end
    end
  end
end
