module SharedResources
  class RemoteUser < ApplicationResource
    self.site = self.root_url + 'api/users/'
    self.element_name = "user"
    self.generate_token

    def self.update_seller(user_id, seller_id)
      post "#{user_id}/update_seller", { seller_id: seller_id }
    end

    def self.get_owners(seller_id)
      get :seller_owners, {seller_id: seller_id}
    end

    def self.get_by_id(user_id)
      get(:get_by_id, { id: user_id }).first
    end

    def self.get_by_email(user_email)
      get(:get_by_email, { email: user_email }).first
    end

    def self.delete_user(user_id)
      delete user_id
    end

    def self.remove_from_supplier(user_id)
      post "#{user_id}/remove_from_supplier"
    end
  end
end 
