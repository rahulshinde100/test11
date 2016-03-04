Spree::User.class_eval do
	attr_accessible :spree_role_ids
	
	# has_one :seller, :dependent => :destroy
	
	# has_one  :seller_user, :through => :seller_users
  # has_one   :store_seller, :class_name => "Spree::Seller", :through => :seller_user

  # ===========
  has_one :seller_user, :dependent => :destroy
  has_one :seller, :through => :seller_user

	scope :sellers, Spree::User.includes(:spree_roles).where("spree_roles.name = 'seller'")

	def has_spree_role?(role_in_question)
    spree_roles.any? { |role| role.name == role_in_question.to_s }
  end

  def name
  	name = "#{self.try(:firstname)} #{self.try(:lastname)}"
  end
end