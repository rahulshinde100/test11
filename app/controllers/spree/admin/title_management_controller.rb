module Spree
  module Admin
    class TitleManagementController < Spree::Admin::BaseController
      authorize_resource :class => Spree::TitleManagement
      respond_to :html

      def update
        p '---------'
        @title_management = Spree::TitleManagement.find(params[:id])
        if @title_management.present?
           market_place_id = @title_management.market_place_id
           name = params[:title][market_place_id.to_s]
           product_id = @title_management.product_id
           begin
             if @title_management.update_attributes!(:market_place_id => market_place_id, :product_id => product_id, :name => name)
               # case @title_management.market_place.code
               #   when "qoo10"
               #     product = @title_management.product
               #     params={}
               #     params = {:product=>{:price=>product.price, :selling_price=>product.selling_price, :special_price=>product.special_price}}
               #     user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", product.seller_id, market_place_id).try(:first)
               #     taxon_market_plcaes = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", product.taxons.first.id, market_place_id).try(:first)
               #     market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", product.seller_id, market_place_id, product.id).try(:first)
               #     # res = view_context.update_product_qoo10(market_place_id, params, product, user_market_place, taxon_market_plcaes, market_place_product, nil, nil, nil)
               #   when "lazada"
               #     # @title_management.update_product_title_to_lazada
               # end
               flash[:notice] = "Product title updated on Market place successfully"
               redirect_to :back
             else
               flash[:error] = "Product title not updated, all fields are mandatory."
               redirect_to :back
             end
           rescue Exception => e
             flash[:error] = e.message
             redirect_to :back
           end
        else
           flash[:error] = "Title not be updated"
           redirect_to :back
        end
      end

       private
        def model_class
          TitleManagement
        end

    end
  end
end
