module Spree
	module Api
		class WishlistsController < Spree::Api::BaseController
			def index
				unless current_api_user.wishlist.wished_products.blank?
					@variants = current_api_user.try(:wishlist).try(:wished_products).collect{|var| [var.variant]}.sum
					@variants = Kaminari.paginate_array(@variants).page(params[:page])
        end
			end

			def create
			      @wished_product = Spree::WishedProduct.new(params[:wished_product])
			      @wishlist = current_api_user.wishlist

			      if @wishlist.include? params[:wished_product][:variant_id]
			        @response = {:response => "Product already exists in your wishlist"}
			        @wished_product = @wishlist.wished_products.detect {|wp| wp.variant_id == params[:wished_product][:variant_id].to_i }
			      else
			        @response = {:response => "Product has been added to your wishlist"}
			        @wished_product.wishlist = current_api_user.wishlist
			        @wished_product.save
			      end
			end

			def remove_product
				@wished_product = Spree::WishedProduct.find_by_variant_id(params[:wished_product][:variant_id])
				if @wished_product
					@wished_product.destroy
					@response = {:response => "Product has been removed from your wishlist"}
				else
					@response = {:error => "Record not found"}
				end

			end

			def clear_wishlist
			      current_api_user.wishlist.wished_products.delete_all
			      @response = {:response => "All Products are removed from your wishlist"}
			end

		end
	end
end
