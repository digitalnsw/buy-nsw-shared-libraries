module SharedResources
  class RemoteSeller < ApplicationResource
    self.site = self.root_url + 'api/sellers/'
    self.element_name = "seller"
    self.generate_token

    def self.public_sellers
      find :all
    end

    def self.telco_sellers
      find :all, params: {telco: true}
    end

    def self.all_services(seller_id)
      get "#{seller_id}/all_services"
    end

    def self.single_seller(seller_id)
      find seller_id
    end

    def self.assign_user(seller_id, user_id, user_email)
      post "#{seller_id}/assign", { assignee: {user_id: user_id, user_email: user_email}}
    end

    def self.approve(seller_id, field_statuses, response)
      post "#{seller_id}/approve", { field_statuses: field_statuses, response: response}
    end

    def self.decline(seller_id, field_statuses, response)
      post "#{seller_id}/decline", { field_statuses: field_statuses, response: response}
    end
  end
end
