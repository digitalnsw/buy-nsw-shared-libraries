module SharedResources
  class RemoteEvent < ApplicationResource
    self.site = self.root_url + 'api/events/'
    self.element_name = "event"
    self.generate_token

    def self.get_events(eventable_id, eventable_type)
      RemoteEvent.find(:all, params: {eventable_id: eventable_id, eventable_type: eventable_type})
    end

    def self.create_event(eventable_id, eventable_type, user_id, category, note)
      create(eventable_id: eventable_id, eventable_type: eventable_type, user_id: user_id, category: category, note: note)
    end
  end
end
