Spree::Taxon.class_eval do
	attr_accessible :lft
	has_many    :seller_categories, :dependent => :destroy
  has_many    :sellers, :through => :seller_categories
end