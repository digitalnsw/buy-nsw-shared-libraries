module SharedResources
  class RemoteNotification < ApplicationResource
    self.site = self.root_url + 'api/notifications/'
    self.element_name = "notification"
    self.connection.auth_type = :bearer
    self.connection.bearer_token = -> { self.bearer_token }


    def self.pending_notification?(unifier:)
      find(unifier).present?
    rescue ActiveResource::ResourceNotFound => e
      false
    end

    def self.create_notification(recipients:, subject:, body:, fa_icon: nil, actions: [], unifier: nil)
      create(unifier: unifier, recipients: recipients, subject: subject, body: body, fa_icon: fa_icon, actions: actions)
    rescue ActiveResource::ClientError => e
      if e.message.match?(/\b406\b/)
        raise SharedModules::AlertError.new('Request canceled! A duplicate request is pending in the queue.')
      else
        raise e.message
      end
    end
  end
end
