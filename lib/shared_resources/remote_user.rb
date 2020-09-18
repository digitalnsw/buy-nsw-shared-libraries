module SharedResources
  class RemoteUser < ApplicationResource
    self.site = self.root_url + 'api/users/'
    self.element_name = "user"
    self.generate_token

    def self.add_to_team(user_id, seller_id)
      post "#{user_id}/add_to_team", { seller_id: seller_id }
    end

    def self.get_team(seller_id)
      find(:all, from: :seller_team, params: { seller_id: seller_id })
    end

    def self.get_owners(seller_id)
      find(:all, from: :seller_owners, params: { seller_id: seller_id })
    end

    def self.get_by_id(user_id)
      find(:one, from: :get_by_id, params: { id: user_id })
    end

    def self.get_by_email(user_email)
      find(:one, from: :get_by_email, params: { email: user_email })
    end

    def self.delete_user(user_id)
      delete user_id
    end

    def self.remove_from_supplier(user_id)
      post "#{user_id}/remove_from_supplier"
    end
  end
end 
