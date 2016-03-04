module Spree
	class ProductNotification < ActiveRecord::Base
	  attr_accessible :user_id, :variant_id
	  belongs_to :variant, :class_name => 'Spree::Variant'
	  belongs_to :user, :class_name => 'Spree::User'
	end
end
