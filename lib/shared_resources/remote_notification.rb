module SharedResources
  class RemoteNotification < ApplicationResource
    self.site = self.root_url + 'api/notifications/'
    self.element_name = "notification"
    self.generate_token

    def self.create_notification(recipients:, subject:, body:, fa_icon: nil, actions: [])
      create(recipients: recipients, subject: subject, body: body, fa_icon: fa_icon, actions: actions)
    end
  end
end
