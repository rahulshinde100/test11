module Spree
  module Admin
    class OptionValuesMarketPlacesController < Spree::Admin::BaseController
      require 'json'

      def map_option_value
        @market_places = Spree::MarketPlace.all
        @api_key_hash = {}
        @market_places.each do |mp|
          seller_market = Spree::SellerMarketPlace.where("market_place_id=? AND is_active=?", mp.id, true)
          seller_market = seller_market.first if seller_market.present?
          @api_key_hash = @api_key_hash.merge(mp.name=>seller_market.api_key) if seller_market.present?
        end
        respond_to do |format|
          format.html { render :partial=>"map_option_value"}
        end
      end

      def search_option_value
        @option_values = []
        @values = Spree::OptionValue.where(:option_type_id=> params[:type_id]).where("name like '%#{params[:term]}%' or presentation like '%#{params[:term]}%'")
        @values.each do |option_value|
          @option_values << {'label' => option_value.presentation, 'id' => option_value.id}
        end if @values.present?
        render :json=>@option_values.to_json
      end

      def get_mapped_value_name
        @mapped_name = Spree::OptionValuesMarketPlace.where(:option_value_id => params[:option_value_id],:market_place_id => params[:market_place_id],:option_type_id =>params[:type_id]).first.name rescue ''
        render :json=>@mapped_name.to_json
      end

      def add_option_value
        @option_value_market_place = Spree::OptionValuesMarketPlace.where("option_value_id=? and option_type_id=? AND market_place_id=? ",params[:option_value_id], params[:option_type_id], params[:market_place_id])
        if @option_value_market_place .present?
          @option_value_market_place.first.update_attributes(:name => params[:name])
        else
          @mp_category = Spree::MarketPlaceCategoryList.find_by_name_and_market_place_id(@market_place_category_name,params[:market_place_id])
          @option_value_market_place = Spree::OptionValuesMarketPlace.create(:option_type_id=>params[:option_type_id], :option_value_id => params[:option_value_id], :market_place_id=>params[:market_place_id],
                                                                           :name=>params[:name])
        end
        respond_to do |format|
          format.html {render :nothing=> true}
        end

      end
    end
  end
end