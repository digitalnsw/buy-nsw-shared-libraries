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
    include SharedModules::Session
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
  end
end
