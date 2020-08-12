require "ostruct"
require "json"
require "jwt"

module SharedModules
  class AccessForbidden < StandardError; end
  class NotAuthorized < StandardError; end
  class NotFound < StandardError; end
  class MethodNotAllowed < StandardError; end
  class NotAcceptable < StandardError; end
  class AlertError < StandardError; end

  module Authentication
    extend ActiveSupport::Concern
    include ActionController::RequestForgeryProtection
    include ERB::Util


    included do
      before_action :set_headers
      protect_from_forgery with: :exception unless Rails.env.test?
      impersonates :user

      rescue_from StandardError, with: :render_500

      rescue_from AccessForbidden, with: :access_forbidden
      rescue_from NotAuthorized, with: :render_unauthorized
      rescue_from NotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveResource::TimeoutError, with: :render_request_timeout
      rescue_from MethodNotAllowed, with: :render_method_not_allowed
      rescue_from ActionController::InvalidAuthenticityToken, with: :csrf_token_invalid
      rescue_from NotAcceptable, with: :render_not_acceptable
      rescue_from AlertError, with: :render_alert
    end

    def render_alert(error)
      render json: {
        errors: [{ alert: error.message }]
      }, status: :unprocessable_entity
    end

    def render_authentication_failed
      render json: {
        errors: ['Authentication failed, please refresh!']
      }, status: :unauthorized #401
    end

    def render_unauthorized
      render json: {
        errors: ['Authorization failed, please refresh!']
      }, status: :unauthorized #401
    end

    def access_forbidden
      render json: {
        errors: ['Access to this page or api is forbidden!']
      }, status: 403
    end

    def csrf_token_invalid
      render json: {
        errors: ['Invalid CSRF token, please try again or refresh the page!']
      }, status: 403
    end

    def render_not_found
      render json: {
        errors: ['Not found']
      }, status: :not_found #404
    end

    def render_method_not_allowed
      render json: {
        errors: ['Method not allowed']
      }, status: :method_not_allowed #405
    end

    def render_not_acceptable
      render json: {
        errors: ['Not acceptable']
      }, status: :not_acceptable #406
    end

    def render_request_timeout
      render json: {
        errors: ['Request timeout']
      }, status: :request_timeout #408
    end

    def render_500(exception)
      if Rails.env.production?
        Airbrake.notify_sync exception
      else
        puts exception.message
        puts exception.backtrace
      end
      render json: {
        errors: [exception],
      }, status: 500
    end

    def update_session_user attrs
      update_concurrent_session({user: attrs})

      @session_user = SharedModules::SessionUser.new(h)
    end

    def reset_session_user user
      my_buyer = user.is_buyer? &&
        SharedResources::RemoteBuyer.my_buyer(user) || nil
      my_seller = user.seller_id &&
        SharedResources::RemoteSeller.find(user.seller_id) || nil

      h = {
        id: user.id,
        email: user.email,
        full_name: user.full_name,
        seller_id: user.seller_id,
        roles: user.roles.to_a,
        buyer_id: my_buyer&.id,
        seller_status: my_seller&.status,
        buyer_status: my_buyer&.state,
      }

      update_concurrent_session({user: h})

      @session_user = SharedModules::SessionUser.new(h)
    end

    def session_user
      if @session_user.nil?
        h = concurrent_session[:user]
        if h.present?
          @session_user = SharedModules::SessionUser.new(h)
        end
      end

      # FIXME The following line is added to fix a bug
      # sometimes the session is outdated. Most probably because race condition.
      # happens more often when sign-in as another user, as it sends multi queries
      # to server and can cause race condition for auth query.
      # another reason could be when user is inactive for half an hour and then
      # takes an action without refreshing the page, if they had ticket remember-me,
      # they stay logged in but session is outdated.

      if current_user&.id != @session_user&.id
        reset_session_user(current_user)
        if Rails.env.production?
          Airbrake.notify_sync StandardError.new('Session user is our of sync again!')
        end
      end

      @session_user
    end

    def service_auth?
      @service_auth.present?
    end

    def service_user
      @service_user
    end

    def set_headers
      response.headers["Expires"] = '0'
      response.headers["Pragma"] = 'no-cache'
      response.headers["Cache-Control"] = "private, no-cache, no-store, must-revalidate, max-age=0, s-maxage=0"
      response.headers["Last-Modified"] = Time.now.strftime("%a, %d %b %Y %T %Z")
    end

    def authenticate_basic
      return true unless Rails.env.production?
      authenticate_or_request_with_http_basic do |username, password|
        username == 'eTendering' && password == ENV['JWT_AUTH_SECRET']
      end
    end

    def authenticate_jwt
      token = request.headers['Authorization'].partition('Bearer ').last
      decoded = JWT.decode(token, ENV['JWT_AUTH_SECRET'], true, { algorithm: 'HS256' }).first
      if Time.now.to_i < decoded['IAT'] || Time.now.to_i > decoded['EXP']
        render_authentication_failed
      end
    rescue
      render_authentication_failed
    end

    def authenticate_service
      token = request.headers['Authentication'].partition('Token ').last
      decoded = JWT.decode(token, ENV['SERVICE_AUTH_SECRET'], true, { algorithm: 'HS256' }).first
      # FIXME: this check is disabled due to active resource problem of not generating header on every request
      # raise "Authentication failed" unless (Time.now.to_i - decoded['timestamp'].to_i).abs < 100
      @service_auth = true
      @service_user = decoded['user'] && SessionUser.new(decoded['user'])
    rescue
      render_authentication_failed
    end

    def authenticate_service_or_admin
      return if current_user.present? && current_user.is_admin?
      authenticate_service
    end

    def authenticate_service_or_user
      return if current_user.present?
      authenticate_service
    end

    def authenticate_user
      return if current_user.present?
      render_authentication_failed
    end

    def redis
      Rails.cache.redis
    end

    def session_timeout
      2.weeks.to_i
    end

    def session_key
      'CONCURRENT_SESSION_' + session.id.to_s if session.id.present?
    end

    def concurrent_session
      @concurrent_session ||= get_concurrent_session
    end

    def get_concurrent_session
      return {} unless session.id.present?
      redis.expire session_key, session_timeout
      v = redis.get(session_key)
      if v
        JSON.parse v, symbolize_names: true
      else
        {}
      end
    end

    def update_concurrent_session h
      return unless session.id.present?
      h = get_concurrent_session.deep_merge(h)
      redis.set session_key, h.to_json
      redis.expire session_key, session_timeout
    end
  end
end
