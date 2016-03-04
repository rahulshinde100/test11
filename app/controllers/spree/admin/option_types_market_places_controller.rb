module Spree
  module Admin
    class OptionTypesMarketPlacesController < Spree::Admin::BaseController
      require 'json'

      def map_option_type
        @market_places = Spree::MarketPlace.all
        @api_key_hash = {}
        @market_places.each do |mp|
          seller_market = Spree::SellerMarketPlace.where("market_place_id=? AND is_active=?", mp.id, true)
          seller_market = seller_market.first if seller_market.present?
          @api_key_hash = @api_key_hash.merge(mp.name=>seller_market.api_key) if seller_market.present?
        end
        respond_to do |format|
          format.html { render :partial=>"map_option_type"}
        end
      end

      def search_option_type
        @option_types = []
        @types = Spree::OptionType.where("name like '%#{params[:term]}%' or presentation like '%#{params[:term]}%'")
        @types.each do |option_type|
           @option_types << {'label' => option_type.presentation, 'id' => option_type.id}
        end if @types.present?
        render :json=>@option_types.to_json
      end

      def get_mapped_name
        @mapped_name = Spree::OptionTypesMarketPlace.where(:market_place_id => params[:market_place_id],:option_type_id =>params[:option_type_id]).first.name rescue ''
        render :json=>@mapped_name.to_json
      end

      def add_option_type
        @option_type_market_place = Spree::OptionTypesMarketPlace.where("option_type_id=? AND market_place_id=? ", params[:option_type_id], params[:market_place_id])
        if @option_type_market_place .present?
          @option_type_market_place.first.update_attributes(:name => params[:name])
        else
          @option_type_market_place = Spree::OptionTypesMarketPlace.create(:option_type_id=>params[:option_type_id], :market_place_id=>params[:market_place_id],
                                                                :name=>params[:name])
        end
        respond_to do |format|
          format.html {render :nothing=> true}
        end

      end
    end
  end
end