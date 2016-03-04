module Spree
  module Admin
    class MarketPlacesController < Spree::Admin::BaseController
      load_and_authorize_resource :class => Spree::MarketPlace
      respond_to :html

      def index
        @render_breadcrumb = breadcrumb_path({:disable => "MarketPlaces"})
        @market_places = Spree::MarketPlace.all
        @market_places = Kaminari.paginate_array(@market_places).page(params[:page]).per(Spree::Config[:admin_products_per_page])
      end

      def new
        @render_breadcrumb = breadcrumb_path({:market_places => admin_market_places_path, :disable => "New"})
        @market_place = Spree::MarketPlace.new
      end

      def create
        @market_place = Spree::MarketPlace.new params[:market_place]
        if @market_place.save!
          redirect_to admin_market_places_path, :notice => "Market Place created successfully"
        else
          render :new
        end
      end

      def edit
        @render_breadcrumb = breadcrumb_path({:market_places => admin_market_places_path, :disable => "Edit"})
        @market_place = Spree::MarketPlace.find(params[:id])
      end

      def update
        @market_place = Spree::MarketPlace.find(params[:id])
        if @market_place.update_attributes(params[:market_place])
          redirect_to admin_market_places_path, :notice => "Market Place updated successfully"
        else
          render "edit"
        end
      end

      def destroy
        @market_place = Spree::MarketPlace.find(params[:id])
        @market_place.destroy
        redirect_to admin_market_places_path, :notice => "Market Place deleted successfully"
      end

      # Added by Tejaswini Patil
      # To add ability for this class n contorller
      private
        def model_class
          MarketPlace
        end
    end
  end
end
