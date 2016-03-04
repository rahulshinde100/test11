module Spree
	module Api
		class BrandsController < Spree::Api::BaseController
			before_filter :load_seller
			def index
				if @seller
			        @brands = @seller_products.collect(&:brand).compact.sort_by{|b| b.name}
			        #@taxons = main_taxons(@seller_products.collect(&:taxons).flatten.uniq)
      			else
	  	 			 @brands = Brand.order(:name)
      			end
      			@brands = @brands.page(params[:page]).per(params[:per_page])
			end

			def products
				@products = Spree::Brand.find_by_permalink(params[:id]).products
				@products = @products.page(params[:page]).per(params[:per_page])
			end
			private
		      def load_seller
		        unless params[:id].blank?
		          @seller = Spree::Seller.find_by_permalink(params[:id])
		        else
		          @seller = current_api_user.seller
		        end
		      end
		end
	end
end
