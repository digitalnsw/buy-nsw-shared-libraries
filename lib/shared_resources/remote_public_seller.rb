module SharedResources
  class RemotePublicSeller < ApplicationResource
    self.site = self.root_url + 'api/sellers/'
    self.element_name = "public_seller"
    self.connection.auth_type = :bearer
    self.connection.bearer_token = -> { self.bearer_token }


    def self.all_active
      find :all, params: { all: true }
    end

    def self.with_identifiers(identifiers)
      find :all, params: { all: true, with_identifiers: identifiers }
    end

    def self.telco_sellers
      find :all, params: { telco: true }
    end
  end
end
