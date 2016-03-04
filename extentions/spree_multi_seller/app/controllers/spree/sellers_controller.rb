require 'rest_client'
module Spree
	class SellersController < Spree::StoreController
		before_filter :load_retailer
		layout :check_layout
		def show
			#Seller must be Active
			@limit = 9 #make it 9 instead of 10, first position will be taken by Promo
      if @seller.nil?
        flash[:success] = "The seller you are looking for is not available"        
        redirect_to [request.protocol, request.domain, request.port_string].join
        return
      end
      @taxons = @categories
      @brands = @seller_products.collect(&:brand).compact.uniq
      @sorted_brands = @brands.sort_by{|b| b.name }
      # @sorted_taxons = @taxons.sort_by{|t|}
      @page = (params[:page].present? ? params[:page] : 1).to_i
      @products = nil
			@style = :product
			@default_image = "product"
			if request.xhr?
        render :partial => "/spree/products/load_product"
        return
      end
		end

    def seller_products
      if @seller.present?
        @limit = 9 #make it 9 instead of 10, first position will be taken by Promo
        taxon = Spree::Taxon.find(params[:taxon_id])
        @page = (params[:page].present? ? params[:page] : 1).to_i
        @seller_products = @seller.products.active
        #@categories = @seller.categories
        @products = @seller_products.includes(:taxons).order("spree_taxons.id, is_new_arrival desc, is_featured desc")
        @products = @products.in_taxon(taxon).order("spree_products.created_at desc").limit(@limit).sort_by{|p| -p.warehouse_discount}.flatten
        if @products.blank?
          render :nothing => true
        else
          render :partial => 'spree/shared/product_new', :locals => { :products => @products, :taxon => taxon}
        end
        
      else
        render :nothing => true
      end
      return
    end

		def locations
			seller = Seller.find_by_permalink(params[:id])
			locations = []
			seller.stock_locations.each do |store|
				store.update_lat_lng if store.lng.nil? or store.lat.nil?
				location ={
					"id" => "#{store.id}",
                                        "name"=> "#{store.name}",
					"locname" => "#{store.try(:locname)}",
					"lat" => "#{store.try(:lat)}",
					"lng" => "#{store.try(:lng)}",
					"address1" => "#{store.try(:address1)}",
					"address2" => "#{store.try(:address2)}",
					"city" => "#{store.try(:city)}",
					"state" => "#{store.try(:state)}",
					"postal" => "#{store.try(:zipcode)}",
					"phone" => "#{store.try(:phone)}",
                                        "web" => "",
					"hours1" => "#{store.try(:operating_hours)}",
					"hours2" => "",
					"hours3" => ""
				}
				locations << location
			end if seller.stock_locations.present?
			render :json => locations.to_json
      return
		end


  end
end
