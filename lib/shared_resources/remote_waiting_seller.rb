module SharedResources
  class RemoteWaitingSeller < ApplicationResource
    self.site = self.root_url + 'api/sellers/'
    self.element_name = "waiting_seller"
    self.generate_token

    def self.find_by_token(token)
      find(:one, from: :find_by_token, params: { token: token })
    rescue ActiveResource::ResourceNotFound
      nil
    end

    def self.initiate_seller(id, owner_id)
      r = post "#{id}/initiate_seller", { owner_id: owner_id }
      JSON.parse(r.body)['seller_id']
    end
  end
end
