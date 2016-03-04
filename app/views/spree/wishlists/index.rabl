
	object false
	child(@wishlist) do
	
		child :products => :products do
		  attributes *product_attributes

		  child :variants_including_master => :variants do
	  	  		attributes *variant_attributes

	  			child :option_values => :option_values do
	    			attributes *option_value_attributes
	  			end
	  
	  			child :images => :images do
	    			extends "spree/api/images/show"
	  			end
		  end
		child :product_properties => :product_properties do
	  		attributes *product_property_attributes
		end
		node(:count) { @products.count }
		node(:total_count) { @products.total_count }
		node(:current_page) { params[:page] ? params[:page].to_i : 1 }
		node(:per_page) { params[:per_page] || Kaminari.config.default_per_page }
		node(:pages) { @products.num_pages }
		end
	end
