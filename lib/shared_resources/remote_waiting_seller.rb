module SharedResources
  class RemoteWaitingSeller < ApplicationResource
    self.site = self.root_url + 'api/sellers/'
    self.element_name = "waiting_seller"
    self.connection.auth_type = :bearer
    self.connection.bearer_token = -> { self.bearer_token }

    def self.find_by_token(token)
      find(:one, from: :find_by_token, params: { token: token })
    rescue ActiveResource::ResourceNotFound
      nil
    end

    def self.initiate_seller(id)
      r = post "#{id}/initiate_seller"
      JSON.parse(r.body)['seller_id']
    end
  end
end
