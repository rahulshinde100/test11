module Spree
	class SellerCategory < ActiveRecord::Base
		attr_accessible :seller_id, :taxon_id

		belongs_to :category, :foreign_key => "taxon_id", :class_name => "Spree::Taxon"
		belongs_to :seller

		validates_presence_of :taxon_id, :seller_id
	end
end
