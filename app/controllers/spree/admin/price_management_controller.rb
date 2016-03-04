module Spree
  module Admin
    class PriceManagementController < Spree::Admin::BaseController
       authorize_resource :class => Spree::PriceManagement
      respond_to :html

      def update
        @price_management = Spree::PriceManagement.find(params[:id])
        if @price_management.present?
           market_place = Spree::MarketPlace.find(params[:market_place_id])
           variant = Spree::Variant.find(params[:variant_id])
           product = variant.product
           selling_price = params[:selling_price][variant.id.to_s][market_place.id.to_s]
           special_price = params[:special_price][variant.id.to_s][market_place.id.to_s]
           settlement_price = params[:settlement_price][variant.id.to_s][market_place.id.to_s] rescue 0.0
           user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", product.seller_id, market_place.id).first
           market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", product.seller_id, market_place.id, product.id).first
           option_name = variant.option_values.present? ? variant.option_values.first.option_type.presentation : ""
           option_value = variant.option_values.present? ? variant.option_values.first.presentation : ""
           begin
           if @price_management.update_attributes(:market_place_id => market_place.id, :variant_id => variant.id, :selling_price => selling_price, :special_price => special_price, :settlement_price => settlement_price)
                # case market_place.code
                # when "qoo10"
                #    #variant.update_variant_qoo10("edit", market_place_product, user_market_place, option_name, option_value, variant)
                # when "lazada"
                #    # variant.update_variant_lazada("edit", market_place_product, user_market_place, option_name, option_value, variant, product)
                # end
               flash[:notice] = "Prices updated successfully"
               redirect_to :back
           else
               flash[:error] = "Price can not be updated, please check special price & settlement price should not be greater than selling price"
               redirect_to :back
           end
           rescue Exception => e
               flash[:error] = e.message
               redirect_to :back
           end
        else
           flash[:error] = "Prices not updated"
           redirect_to :back
        end
      end
      private
        def model_class
          PriceManagement
        end
    end
  end
end
