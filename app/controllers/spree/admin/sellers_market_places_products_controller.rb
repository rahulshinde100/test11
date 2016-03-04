module Spree
  module Admin
    class SellersMarketPlacesProductsController < Spree::Admin::BaseController
      authorize_resource :class => Spree::SellersMarketPlacesProduct
      
      def load_market_places
        @market_places = []
        @product = Spree::Product.find(params[:product_id])
        @seller = Spree::Seller.where("id=?", params[:seller_id]).first
        @market_places = @seller.market_places.where('is_active=?', true) if !@seller.blank?
        @selected_mp_ids = Spree::SellersMarketPlacesProduct.where("seller_id=? AND product_id=?", params[:seller_id], params[:product_id])
        @selected_mp_ids = @selected_mp_ids.pluck(:market_place_id) if !@selected_mp_ids.blank?
        respond_to do |format|
          format.html { render :partial=>"load_market_places"}
        end
      end

      def pre_mapped_market_places
        @market_places = []
        @seller = Spree::Seller.where("id=?", params[:seller_id]).first
        @market_places = @seller.market_places.where('is_active=?', true) if !@seller.blank?
        @selected_mp_ids = Spree::SellersMarketPlacesProduct.where("seller_id=? AND product_id=?", params[:seller_id], params[:product_id])
        respond_to do |format|
           format.html { render :partial=>"pre_mapped_market_places"}
        end
      end
      
      # unmapped product from marketplace
      def unmapped_market_place
        smp = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", params[:seller_id], params[:market_place_id]).try(:first)
        seller = smp.seller
        smpp = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", params[:seller_id], params[:market_place_id], params[:product_id]).try(:first)
        product = smpp.product
        market_place = smpp.market_place
        #smpp.try(:first).destroy if smpp.present?
        case market_place.code
        when "qoo10"
          ApiJob.change_product_status_on_qoo10(smp, smpp, "inactive")  
        when "lazada", "zalora"
          ApiJob.change_product_status_on_lazada(smp, [product], "inactive")   
        end
        body = "Dear Team,<br />"
        body += "<p>Product unmapped from following marketplace.<br /><br />"
        body += "<table cellpadding='1' cellspacing='1' border='black'>
                   <thead><tr><th>Seller</th><th>Product Name</th><th>SKU</th><th>Time When Unmapped(SGT)</th><th>Marketplace</th></tr></thead>
                   <tbody><tr><td>#{seller.name.capitalize}</td><td>#{product.name}</td><td>#{product.sku}</td><td>#{Time.zone.now().strftime("%a %b %d %Y %H:%M:%S %p")}</td><td>#{market_place.name.capitalize}</td></tr></tbody></table>"
        body +="<br /><br /><p>For any queries, help@anchanto.com.<br /></p>"                 
        subject = "Channel Manager | Unmapped Product"
        if Rails.env.eql?('production')
          emails = ["ritika.shetty@anchanto.com", "swapnil.gadewar@anchanto.com"]
        elsif Rails.env.eql?('development')  
          emails = ["abhijeet.ghude@anchanto.com"]
        else  
          emails = ["gajanan.deshpande@anchanto.com", "abhijeet.ghude@anchanto.com"]
        end
        if CustomMailer.custom_order_export(emails, subject, body).deliver
          smpp.update_attributes!(:unmap_mail_sent_at=>Time.zone.now())    
        end
        respond_to do |format|
          format.html {render :nothing=> true}
        end
      end

      def load_market_places_on_product_import
         @market_places = []
         @seller = Spree::Seller.where("id=?", params[:seller_id]).first
         @market_places = @seller.market_places.where('is_active=?', true) if !@seller.blank?
         respond_to do |format|
           format.html { render :partial=>"load_market_places_on_bulk_import"}
        end
      end

      def load_market_places_on_product_listing
         @market_places = []
         @seller = Spree::Seller.where("id=?", params[:seller_id]).first
         @market_places = @seller.market_places.where('is_active=?', true) if !@seller.blank?
         respond_to do |format|
           format.html { render :partial=>"load_market_places_on_bulk_listing"}
        end
      end

      def load_market_places_on_product_export
         @market_places = []
         @seller = Spree::Seller.where("id=?", params[:seller_id]).first
         @market_places = @seller.market_places.where('is_active=?', true) if !@seller.blank?
         respond_to do |format|
           format.html { render :partial=>"load_market_places_on_bulk_export"}
        end
      end

      def show_seller_products
         @products = []
         @seller = Spree::Seller.where("id=?", params[:seller_id]).first
         @products  = @seller.products if !@seller.blank?
         @products = Kaminari.paginate_array(@products).page(params[:page]).per(Spree::Config[:admin_products_per_page])
          respond_to do |format|
            #format.html { render :partial=>"seller_products"}
            format.js
          end
      end

      # Added by Tejaswini Patil
      # To add ability
      private
        def model_class
          SellersMarketPlacesProduct
        end
    end
  end
end
