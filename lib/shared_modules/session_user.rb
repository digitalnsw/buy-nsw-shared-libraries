require "json"

module SharedModules
  class SessionUser
    attr_reader :id, :uuid, :email, :full_name, :seller_id, :seller_ids, :buyer_id, :roles, :permissions, :seller_status, :buyer_status

    def initialize hash
      hash.transform_keys!(&:to_sym)
      @id = hash[:id]
      @email = hash[:email]
      @uuid = hash[:uuid]
      @full_name = hash[:full_name]
      @seller_id = hash[:seller_id]
      @seller_ids = hash[:seller_ids]
      @buyer_id = hash[:buyer_id]
      @roles = hash[:roles]
      @permissions = hash[:permissions]
      @seller_status = hash[:seller_status]
      @buyer_status = hash[:buyer_status]
    end

    def to_hash
      [:id, :uuid, :email, :full_name, :seller_id, :seller_ids, :buyer_id, :roles, :permissions, :seller_status, :buyer_status].map { |k|
        [k, send(k)]
      }.to_h
    end

    def is_seller?
      roles.include? 'seller'
    end

    def seller_is_live?
      is_seller? && seller_status.in?(['live', 'amendment_draft', 'amendment_pending', 'amendment_changes_requested'])
    end

    def can? seller_id, action
      permissions[seller_id.to_s] && permissions[seller_id.to_s].include?(action.to_s)
    end

    def privileges seller_id
      permissions[seller_id.to_s]
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
