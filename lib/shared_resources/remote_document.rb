module SharedResources
  class RemoteDocument < ApplicationResource
    self.site = self.root_url + 'api/documents/'
    self.element_name = "document"
    self.connection.auth_type = :bearer
    self.connection.bearer_token = -> { self.bearer_token }


    def self.get_documents(ids)
      find :all, params: {ids: ids}
    end

    def self.can_attach?(seller_id, document_ids)
      get :can_attach, { seller_id: seller_id, document_ids: document_ids }
    end
  end
end
