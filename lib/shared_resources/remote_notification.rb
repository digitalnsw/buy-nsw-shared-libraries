module SharedResources
  class RemoteNotification < ApplicationResource
    self.site = self.root_url + 'api/notifications/'
    self.element_name = "notification"
    self.generate_token

    def self.create_notification(user_id, subject, body, fa_icon, actions)
      create(user_id: user_id, subject: subject, body: body, fa_icon: fa_icon, actions: actions)
    end
  end
end
