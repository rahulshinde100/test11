module Spree
	class SellerUser < ActiveRecord::Base
  	attr_accessible :seller_id, :user_id, :dateofbirth

		# belongs_to  :store_user, :class_name => "Spree::User"
		# belongs_to 	:seller
		# ======================

		belongs_to :user
		belongs_to :seller
		
		validates_presence_of :user_id, :seller_id
	end
end
