module Spree
  module Api
    class MarketPlacesController < Spree::Api::BaseController

      def index
        if params[:ids]
          @market_places = Spree::MarketPlace.where(:id => params[:ids].split(','))
        else
          @market_places = Spree::MarketPlace.ransack(params[:q]).result
        end
        respond_with(@market_places)
      end

    end
  end
end
