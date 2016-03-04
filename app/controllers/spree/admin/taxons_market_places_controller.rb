module Spree
  module Admin
    class TaxonsMarketPlacesController < Spree::Admin::BaseController
      require 'json'

      def mapped_categories
          @taxon = Spree::Taxon.find(params[:id])
          @market_places = Spree::MarketPlace.all
          @api_key_hash = {}
          @market_places.each do |mp|
            seller_market = Spree::SellerMarketPlace.where("market_place_id=? AND is_active=?", mp.id, true)
            seller_market = seller_market.first if seller_market.present?
            @api_key_hash = @api_key_hash.merge(mp.name=>seller_market.api_key) if seller_market.present?
          end
          respond_to do |format|
             format.html { render :partial=>"mapped_categories"}
          end
      end

      def pre_mapped_categories
        @taxon_market_places = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", params[:taxon_id], params[:market_place_id])
        @taxon = Spree::Taxon.find(params[:taxon_id])
        respond_to do |format|
          format.html { render :partial=>"pre_mapped_categories"}
        end
      end

      # Commented by Tejaswini Patil
      # Added new method for single selection
      # Which is based on mp_category name and not id

      # def add_categories
      #     @taxon = Spree::Taxon.find(params[:taxon_id])
      #     @market_place_category_ids = params[:market_place_category_id].split(",")
      #     @market_place_category_names = params[:market_place_category_name].split(",")
      #     @market_place_category_ids.each_with_index do |mpc, index|
      #       @market_place_category = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=? AND market_place_category_id=?", params[:taxon_id], params[:market_place_id], mpc)
      #       @taxon_market_place = Spree::TaxonsMarketPlace.create(:taxon_id=>params[:taxon_id], :market_place_id=>params[:market_place_id],
      #     :market_place_category_id=>mpc, :name=>@market_place_category_names[index].to_s) if @market_place_category.blank?
      #     end
      #     respond_to do |format|
      #       format.html {render :nothing=> true}
      #     end
      # end

      def add_categories
          @taxon = Spree::Taxon.find(params[:taxon_id])
          @market_place_category_name = params[:market_place_category_name]
          @taxon_market_place = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=? AND name=?", params[:taxon_id], params[:market_place_id],  @market_place_category_name)
          unless @taxon_market_place.present?
            @mp_category = Spree::MarketPlaceCategoryList.find_by_name_and_market_place_id(@market_place_category_name,params[:market_place_id])
            @taxon_market_place = Spree::TaxonsMarketPlace.create(:taxon_id=>params[:taxon_id], :market_place_id=>params[:market_place_id],
          :market_place_category_id=>@mp_category.category_code, :name=>@market_place_category_name) if @mp_category.present?
          end
          respond_to do |format|
            format.html {render :nothing=> true}
          end
      end

      def unmapped_category
        @market_place_category = Spree::TaxonsMarketPlace.where("id=?", params[:id])
        @market_place_category.first.destroy if !@market_place_category.blank?
        respond_to do |format|
          format.html {render :nothing=> true}
        end
      end

      def get_all_market_place_categories
        @categories = []
        begin
          @market_place = Spree::MarketPlace.find_by_name(params[:market_place])
          @categories = Spree::MarketPlaceCategoryList.where("market_place_id=?", @market_place.id)
        rescue Exception => e
          
        end    
        respond_to do |format|
          format.html {render :partial=> "load_market_place_categories"}
        end
      end

      def get_categories
        @categories = []
        begin
          market_place = Spree::MarketPlace.find(params[:market_place])
          @categories = Spree::MarketPlaceCategoryList.where("market_place_id=?", market_place.id).map(&:name)#.map{|mc| [mc.id,mc.name]}
        rescue Exception => e
          
        end
        render :json => @categories.to_json
      end

    end
  end
end
