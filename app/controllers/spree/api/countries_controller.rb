module Spree
  module Api
    class CountriesController < Spree::Api::BaseController

      def index
        @countries = Country.ransack(params[:q]).result.
                     includes(:states).order('name ASC')

        respond_with(@countries)
      end

      def show
        @country = Country.find(params[:id])
        respond_with(@country)
      end
    end
  end
end