module SharedResources
  class RemoteProduct < ApplicationResource
    self.site = self.root_url + 'api/products/'
    self.element_name = "product"
    self.generate_token

    def self.assign_user(product_id, user_id, user_email)
      post "#{product_id}/assign", { assignee: {id: user_id, email: user_email}}
    end

    def self.approve(product_id, field_statuses, response)
      post "#{product_id}/approve", { field_statuses: field_statuses, response: response}
    end

    def self.decline(product_id, field_statuses, response)
      post "#{product_id}/decline", { field_statuses: field_statuses, response: response}
    end
  end
end
