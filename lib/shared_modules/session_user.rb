require "json"

module SharedModules
  class SessionUser
    attr_reader :id, :email, :full_name, :seller_id, :buyer_id, :roles, :seller_status, :buyer_status

    def initialize hash
      hash.transform_keys!(&:to_sym)
      @id = hash[:id]
      @email = hash[:email]
      @full_name = hash[:full_name]
      @seller_id = hash[:seller_id]
      @buyer_id = hash[:buyer_id]
      @roles = hash[:roles]
      @seller_status = hash[:seller_status]
      @buyer_status = hash[:buyer_status]
    end

    def to_hash
      [:id, :email, :full_name, :seller_id, :buyer_id, :roles, :seller_status, :buyer_status].map { |k|
        [k, send(k)]
      }.to_h
    end

    def is_seller?
      roles.include? 'seller'
    end

    def seller_is_live?
      is_seller? && seller_status.in?(['live', 'amendment_draft', 'amendment_pending', 'amendment_changes_requested'])
    end

    def can_buy?
      is_buyer? && buyer_status == 'approved'
    end

    def is_buyer?
      roles.include? 'buyer'
    end

    def is_admin?
      roles.include? 'admin'
    end

    def is_superadmin?
      roles.include? 'superadmin'
    end
  end
end
