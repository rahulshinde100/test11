module Spree
  module Api
    class SellersController < Spree::Api::BaseController
      before_filter :load_seller, :except => :index
      before_filter :verify_seller, :except => [:index, :products, :show]

      def index
        @sellers = Spree::Seller.is_active
        unless @sellers
          invalid_resource!(@sellers)
        end
        if params[:ids]
          @sellers = Spree::Seller.is_active.where(:id => params[:ids].split(','))
        else
          @sellers = Spree::Seller.is_active.ransack(params[:q]).result
        end

        respond_with(@sellers)
      end

      def show
        @seller = Spree::Seller.find_by_permalink(params[:id])
      end

      def products
        @seller = Spree::Seller.find_by_permalink(params[:id])
        @products =  @seller.products.active
        @products = @products.page(params[:page]).per(params[:per_page])
      end

      def orders
        @seller = Spree::Seller.find_by_permalink(params[:id])
        @orders =  @seller.orders
        @orders = @orders.page(params[:page]).per(params[:per_page])
      end

      def seller_orders
        @line_items = []
        @seller = current_api_user.seller
        @orders = @seller.orders.complete.order("spree_orders.completed_at desc")
        @orders.each do |order|
          order = order.seller_line_items(@seller)
        end
        @orders = @orders.page(params[:page]).per(params[:per_page])
        @num_pages = @orders.num_pages 
        @total_count = @orders.total_count 
        #@orders = @orders.sort_by(&:shipping_category)

      end

      def updated_data_status
        if Spree::OptionType.last_updated(params[:date]).present? || Spree::OptionValue.last_updated(params[:date]).present? || Spree::Property.last_updated(params[:date]).present? || Spree::Prototype.last_updated(params[:date]).present? || Spree::Taxon.last_updated(params[:date]).present? || Spree::User.last_updated(params[:date]).present? ||  Spree::StockLocation.last_updated(params[:date]).present?
          @data_status = {:status => "true"}
        else
          @data_status = {:status => "false"}
        end
      end

      def users
        @users = @seller.users
        @users = @users.page(params[:page]).per(params[:per_page])
      end

      def seller_roles
        @seller_roles = Spree::Seller.seller_users_roles
        render :json => @seller_roles
      end

      def categories
        @seller = current_api_user.seller
        @categories = @seller.categories
      end

      def stock_locations
        @seller = current_api_user.seller
        @locations = @seller.stock_locations
        @locations =@locations.page(params[:page]).per(params[:per_page])
      end

      def category_products
        @seller = current_api_user.seller
        @taxon = Spree::Taxon.find_by_permalink!(params[:id])
        return unless @taxon
        @products = @taxon.products.where("spree_products.seller_id = #{@seller.id}").order("spree_products.name").page(params[:page]).per(10)
      end

      # change the state of line item for delivery
      def ready_for_pickup
        @seller = current_api_user.seller
        @order = Spree::Order.find(params['order']['id'])
        unless @seller.nil? || @order.nil? 
          line_items = params['order']['line_items']
          line_items.each do |line_item|
            lt = Spree::LineItem.find(line_item['id'])
            if line_item['picked_up']
              lt.update_attribute_without_callbacks(:picked_up, line_item['picked_up'].to_bool)
            else
              lt.update_attribute_without_callbacks(:ready_for_pickup, line_item['ready_for_pick_up'].to_bool )  
              RestClient.put("#{OMS_PATH}/update_line_item_status/#{@order.number}", :api_key => OMS_API_KEY, :line_item_id => lt.id)
            end
          end
          @order = Spree::Order.find(params['order']['id'])
        else
          @error = {:error => "something went wrong"}
        end

      end

      def product_search
         key = params[:keyword]
         q = {"name_or_description_cont"=>"#{key}"}
         @products = @seller.products.approved.active.ransack(q).result.page(params[:page])
      end

      private
      def load_seller
        unless params[:id].blank?
          @seller = Spree::Seller.find_by_permalink(params[:id])
        else
          @seller = current_api_user.seller
        end
      end

    end

  end
end
