Spree::Product.class_eval do
	attr_accessible :seller_id, :created_by, :updated_by, :is_approved, :reject_reason, :is_reject, :deleted_at
 
 	# validates_presence_of :seller_id, :created_by, :updated_by
	belongs_to :seller

	belongs_to :created, :foreign_key => "created_by", :class_name => "Spree::User"
	belongs_to :updated, :foreign_key => "updated_by", :class_name => "Spree::User"

	scope :approved, where(:is_approved => true)
	scope :un_approved, where(:is_approved => false)
	scope :warehouse_sale, where(:is_warehouse => true)

  def self.active(currency = nil)
    not_deleted.available(nil, currency).approved
  end
end