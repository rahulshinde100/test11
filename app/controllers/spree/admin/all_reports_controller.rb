module Spree
  module Admin
    class AllReportsController < Spree::Admin::BaseController

      respond_to :html

      def index
      	@seller_wise_orders = Spree::Seller.joins(:orders).group(:name).count
      end

      def current_monthly_cancel_orders

      			@current_monthly_cancel_orders = Spree::Order.group(:is_cancel).count
      end

   end
  end
end    