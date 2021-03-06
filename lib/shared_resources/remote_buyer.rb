module SharedResources
  class RemoteBuyer < ApplicationResource
    self.site = self.root_url + 'api/buyers/'
    self.element_name = "buyer"
    self.connection.auth_type = :bearer
    self.connection.bearer_token = -> { self.bearer_token }

    def self.manager_approval(token)
      post :approve_buyer, {manager_approval_token: token}
    end

    def self.check_email(email)
      get(:check_email, { email: email })['valid']
    end

    def self.auto_register(email:, user_id:, name:)
      post(:auto_register, { email: email, user_id: user_id, name: name })
    end

    def can_buy?
      self.state == 'approved'
    end

    def self.buyer_active?(user)
      RemoteBuyer.generate_token(user)
      RemoteBuyer.get(:can_buy)
    end

    def self.my_buyer(user)
      RemoteBuyer.generate_token(user)
      RemoteBuyer.find(:all, from: :my_buyer).first
    end

    def self.assign_user(buyer_id, user_id, user_email)
      post "#{buyer_id}/assign", { assignee: {user_id: user_id, user_email: user_email}}
    end

    def self.approve(buyer_id, response)
      post "#{buyer_id}/approve", { response: response }
    end

    def self.decline(buyer_id, response)
      post "#{buyer_id}/decline", { response: response }
    end

    def self.deactivate(buyer_id)
      post "#{buyer_id}/deactivate"
    end
  end
end
