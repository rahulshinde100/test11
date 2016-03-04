module Spree
	Taxonomy.class_eval do

		#attr_accessible :product_count

		default_scope :order => 'name ASC'

    def self.categories
      where(:name => "Categories").try(:first)
    end

		def product_count(id)
			count = 0
			self.taxons.each do |taxon|
				count = count + taxon.products.where(:seller_id => id).count
			end
		end
	end
end
