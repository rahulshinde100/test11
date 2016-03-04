module Spree::ProductsHelper
	def get_product_conut(key)
		if !key[:taxon].blank?
			@count = Spree::Product.sale_products_by_category(params[:taxon]).count
            elsif !key[:retailer].blank?
                  @count = Spree::Product.sale_products_by_sellers(key[:retailer]).count
  	      end
  		return @count
  end
end