module Spree
  module Admin
    class AllReportsController < Spree::Admin::BaseController

      respond_to :html

      def index
      	@seller_wise_orders = Spree::Seller.joins(:orders).group(:name).count
      end

     

   end
  end
end    