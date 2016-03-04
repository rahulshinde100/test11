require 'rest_client'
Spree::Admin::OrdersController.class_eval do
before_filter :authenticate_spree_user!
load_and_authorize_resource :class => Spree::Order, :find_by => :number

    # Added by Tejaswini Patil
    # For search method
    def search_reasult(search_params)
        puts search_params
        # Available FBA States
        @fba_states = [["All", nil], ["Picking Line", ["rfp", "assign_for_pickup"]], ["Packing Line", ["picked_up", "assign_for_packup"]], ["Out For Delivery", ["delivery", "redelivery"]], ["Cancelled", ["cancel"]], ["Completed", ["complete", "customer_complete", "self_collect_complete", "collect_complete", "return_complete"]]]
        @customer_pickup = false

        # Collect all search params if available
        if params[:order].present?
            @customer_pickup = params[:order][:is_pick_at_store] == "true" ? true : false
            @seller_id = params[:order][:seller_id]
            @market_place_id = params[:order][:market_place_id]
            @fba_state = params[:order][:fba_state]
            @formatted_state = @fba_state.tr('"', '').gsub("[","").gsub("]","").split(",").map(&:lstrip) if @fba_state.present?
            @search_text = params[:order][:search_text]
        end

        # Initialize an array to collect the search query condition
        @query_conditions = []

        if params[:created_at_lt].present? && params[:created_at_gt].present?
            st_date = params[:created_at_gt].to_date.beginning_of_day
            end_date = params[:created_at_lt].to_date.end_of_day
            @query_conditions << " order_date BETWEEN '#{st_date}' AND '#{end_date}'"
        end

        # Check for all search parameters and create query conditions accordingly
        if @customer_pickup.present?
           @query_conditions << "spree_line_items.is_pick_at_store = #{@customer_pickup}"
        end
        if @market_place_id.present?
           @query_conditions << " market_place_id = #{@market_place_id}"
        end
        if @search_text.present?
           @query_conditions << " (number like '%#{@search_text}%' OR market_place_order_no like '%#{@search_text}%' OR cart_no like '%#{@search_text}%' OR fulflmnt_tracking_no like '%#{@search_text}%' OR spree_addresses.firstname like '%#{@search_text}%' )"
        end
        if @formatted_state.present?
            # Check for selected seller and collect his orders and match selected fba state
            if @seller_id.present?
               @seller = Spree::Seller.find(params[:order][:seller_id])
               @orders = @seller.orders.where(:fulflmnt_state => @formatted_state)
            else
                @orders = @orders.where(:fulflmnt_state => @formatted_state)
            end
        else
            if @seller_id.present?
               @seller = Spree::Seller.find(params[:order][:seller_id])
               @orders = @seller.orders
            end
        end

        # Combine all query conditions in single
        @query_conditions = @query_conditions.join(' and ')

        # Check for loged in user role
        if spree_current_user.has_spree_role?('seller')
            @market_places = spree_current_user.seller.market_places
            @seller = spree_current_user.try(:seller)
            @orders = @orders.includes(:line_items,:ship_address).where(""+@query_conditions)
        else
            @sellers = Spree::Seller.all
            @market_places = Spree::MarketPlace.all
            @orders = @orders.includes(:line_items,:ship_address).where(""+@query_conditions)
        end
    end

    # Complete Index Method is modified BY Tejaswini Patil and improved by Abhijeet Ghude
    # To optimize search functionality.
    def index
      p '-------'
      @orders = search_reasult(params).order('order_date desc')
      @orders = Kaminari.paginate_array(@orders).page(params[:page]).per(params[:per_page] || Spree::Config[:orders_per_page])
    end

    # Added by Tejaswini Patil and improved by Abhijeet Ghude
    # Method to show the complete orders
    def complete_orders
      @orders = search_reasult(params).where("fulflmnt_state = 'complete'").order('order_date desc')
      @orders = Kaminari.paginate_array(@orders).page(params[:page]).per(params[:per_page] || Spree::Config[:orders_per_page])
    end

    # Added by Tejaswini Patil and improved by Abhijeet Ghude
    # Method to show cancelled orders
    def cancel_orders
      @orders = search_reasult(params).where("fulflmnt_state = 'cancel'").order('order_date desc')
      @orders = Kaminari.paginate_array(@orders).page(params[:page]).per(params[:per_page] || Spree::Config[:orders_per_page])
    end

    # Method to show the partial orders
    def partial_orders
      @orders = search_reasult(params).includes(:line_items).where("fulflmnt_tracking_no IS NULL AND is_cancel=false").order('order_date desc')
      @orders = Kaminari.paginate_array(@orders).page(params[:page]).per(params[:per_page] || Spree::Config[:orders_per_page])
    end

    def disputed_cancel_orders
      @orders = search_reasult(params).includes(:line_items).where("cancel_on_fba=false AND is_cancel=true").order('order_date desc')
      @orders = Kaminari.paginate_array(@orders).page(params[:page]).per(params[:per_page] || Spree::Config[:orders_per_page])
    end

  # To sync all orders in SF from Qoo10, clubbed/merged it according to cart and then push to FBA
  def all_orders_sync
     @all_partial_orders = Spree::Order.includes(:line_items).where("spree_line_items.id is null")
      if !@all_partial_orders.present? || @all_partial_orders.count == 0
          flash[:error] = "No orders found to sync"
          redirect_to partial_orders_admin_orders_path
          return
      else
          res = view_context.sync_all_orders_qoo10(@all_partial_orders)
          redirect_to partial_orders_admin_orders_path, :notice => "All orders synced successfully!"
      end
  end

  def show
    @order = Spree::Order.find_by_number(params[:id])
    @related_orders = !@order.nil? && @order.cart_no.present? ? Spree::Order.where(:cart_no => @order.cart_no).order("number ASC") : nil
  end

  def modify_order
    @order = Spree::Order.find_by_number(params[:id])
  end

  # Method to load products skus on add product form in order
  def load_products_skus
        @order = Spree::Order.find_by_id(params[:order_id])
        respond_to do |format|
           format.html { render :partial=>"add_lineitems"}
        end
  end

  # Method to auto-complete variant SKU search
  def product_skus_json
        @product_skus_json = []
        @order = Spree::Order.find_by_id(params[:order_id])
        @products = @order.seller.products.where(:kit_id=>nil) if @order.present?
        @products.each do |product|
           product_variants = []
           product_variants << (product.variants.present? ? product.variants : product.master)
           product_variants = product_variants.flatten
           product_variants.each do |pv|
              #name = (pv.option_values.present? ? (product.name+" -> "+pv.option_values.first.presentation+" ("+pv.sku.to_s+")") : (product.name+" ("+pv.sku.to_s+")"))
             if !pv.parent_id.present?
               name = pv.sku.to_s
               @product_skus_json << {'label' => name, 'id' => pv.id} if name.downcase.include? params[:term].downcase
             end
           end
         end if @products.present?
         render :json=>@product_skus_json.to_json
  end

  # Method to add variant sku in order
  def add_product_skus
        @order = Spree::Order.find_by_id(params[:order_id])
        @variant = Spree::Variant.find_by_id(params[:variant_id])
        @product = @variant.product
        requested_qty = params[:quantity]
        is_customer_pickup = @order.market_place_details.present? ? (@order.market_place_details["OrderType"] == "Pickup" ? true : false) : false
        # code to find the order_total
        if @order.market_place.present?
           case @order.market_place.code
           when "qoo10"
               order_total = @order.market_place_details.present? ? @order.market_place_details["total"] : @order.total
           when "lazada",'zalora'
               order_total = @order.total
           end
        end
         # code to create line item
        price = @variant.price.present? ? @variant.price : 0.0 
        @line_item = Spree::LineItem.create!(:variant_id=>@variant.id, :order_id=>@order.id, :quantity=>requested_qty, :price=>price, :currency=>@order.currency, :is_pick_at_store => is_customer_pickup)
         if @line_item.present?
               @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @order.seller_id, @order.market_place_id, @product.id).try(:first)
                if @sellers_market_places_product.present?
                   @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, @variant.id).try(:first)
                      if @stock_product.present?
                         @stock_product.update_attributes(:count_on_hand=>(@stock_product.count_on_hand - requested_qty.to_i) >= 0 ? (@stock_product.count_on_hand - requested_qty.to_i) : 0)
                         @variant.update_attributes(:fba_quantity=>(@variant.fba_quantity - requested_qty.to_i) >= 0 ? (@variant.fba_quantity - requested_qty.to_i) : 0) if !@variant.quantity_inflations.present?
                         msg = 'Admin/Orders Controller add_product_skus Line 182'
                         @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
                      else
                         @stock_product = Spree::StockProduct.create!(:sellers_market_places_product_id=>@sellers_market_places_product.id, :variant_id=>@variant.id, :count_on_hand=>requested_qty.to_i, :virtual_out_of_stock=>false)
                         @variant.update_attributes(:fba_quantity=>(@variant.fba_quantity - requested_qty.to_i) >= 0 ? (@variant.fba_quantity - requested_qty.to_i) : 0) if !@variant.quantity_inflations.present?
                         msg = 'Admin/Orders Controller add_product_skus Line 187'
                         @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
                      end
                end
         end
        # code to update order total after creating line item for order
        @order.update_column(:total, order_total)
        @order.reload
        line_items = @order.line_items
        ActiveSupport::Notifications.instrument('spree.order.contents_changed', {:user => nil, :order => @order})
        respond_to do |format|
            format.html { render :partial=>"modify_shipping", :locals => { :line_items => line_items }}
        end
  end

  # Method to load existing variant sku on edit product form in order
  def load_existing_variant_sku
        @order = Spree::Order.find_by_id(params[:order_id])
        @line_item = Spree::LineItem.find_by_id(params[:line_item_id])
        respond_to do |format|
           format.html { render :partial=>"edit_lineitems"}
        end
  end

  # Method to update variant qty in order
  def update_product_qty
      @order = Spree::Order.find_by_id(params[:order_id])
      @line_item = Spree::LineItem.find_by_id(params[:line_item_id])
       request_to_update_qty = params[:quantity].to_i
       # code to find the order_total
       if @order.market_place.present?
            case @order.market_place.code
            when "qoo10"
                order_total = @order.market_place_details.present? ? @order.market_place_details["total"] : @order.total
            when "lazada", 'zalora'
                order_total = @order.total
            end
       end
       if @line_item.present?
          prev_qty = @line_item.quantity.to_i
          final_qty = prev_qty - request_to_update_qty
          @variant = @line_item.variant
          @product = @variant.product if @variant.present?
          # code to update line item
          @line_item.update_column(:quantity, request_to_update_qty)
          @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @order.seller_id, @order.market_place_id, @product.id).try(:first)
            if @sellers_market_places_product.present?
               @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, @variant.id).try(:first)
                if @stock_product.present?
                   @stock_product.update_attributes(:count_on_hand=>(@stock_product.count_on_hand + final_qty.to_i) >= 0 ? (@stock_product.count_on_hand + final_qty.to_i) : 0)
                   @variant.update_attributes(:fba_quantity=>(@variant.fba_quantity + final_qty.to_i) >= 0 ? (@variant.fba_quantity + final_qty.to_i) : 0) if !@variant.quantity_inflations.present?
                     msg = 'Admin/Orders Controller update_product_qty '
                     @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
                end
            end
       end
       # code to update order total after creating line item for order
      @order.update_column(:total, order_total)
      @order.reload
       line_items = @order.line_items
       respond_to do |format|
           format.html { render :partial=>"modify_shipping", :locals => { :line_items => line_items }}
       end
  end

  # Method to validate the push to fba action
  def validate_push_to_fba
    @order = Spree::Order.find_by_number(params[:id])
    cart_no = @order.cart_no if @order.present?
    @orders = Spree::Order.where(:cart_no => cart_no)
    @errors = []
    if @orders.present?
      @orders.each do |order|
        @line_items = order.line_items if order.line_items.present?
        if @line_items.present?
          @line_items.each do |line_item|
            @errors << line_item.variant.sku.to_s+" sku is out of stock on FBA" if line_item.variant.fba_quantity < 0
          end
        else
          flash[:error] = order.market_place_order_no.to_s+" : No line items found..."  
        end
      end
    end
    if @errors.present? && @errors.count > 0
      flash[:error] = "Ooop's "+ @errors.join(', ') 
      redirect_to modify_order_admin_order_path(@order)
    else
      cart_numbers = []
      cart_numbers << cart_no
      Spree::Order.push_to_fba(cart_numbers)
      flash[:success] = "Order Pushed to FBA Successfully !"
      redirect_to admin_order_path(@order)
    end
  end

  def update_line_item_status
    @order = Spree::Order.find_by_number(params[:id])
    if params[:picked_up].present?
      @order.line_items.find(params[:line_item_id]).update_attribute_without_callbacks(:picked_up, params[:picked_up])
      @line_item = @order.line_items.find(params[:line_item_id])
    else
      @order.line_items.find(params[:line_item_id]).update_attribute_without_callbacks(:ready_for_pickup, params[:ready_for_pickup])
      @line_item = @order.line_items.find(params[:line_item_id])
       resp = RestClient.put("#{OMS_PATH}/update_line_item_status/#{@order.number}", :api_key => OMS_API_KEY, :line_item_id => @line_item.id)
    end
    respond_to :js
  end

  def oms_success
    @oms_order_logs = Spree::OmsLog.success.page(params[:page]).per(50)
  end

  def oms_pending
    @oms_order_logs = Spree::OmsLog.pending.page(params[:page]).per(50)
  end

  def resend
    @order.deliver_order_confirmation_email
    flash[:success] = Spree.t(:order_email_resent)
    redirect_to :back
  end

  def invoice_show
    load_order
    respond_with(@order) do |format|
      format.html {render :layout => false}
      format.pdf do
        render :pdf => "#{@order.number}"
      end
    end
  end

  def show_invoice
    @order = Spree::Order.find_by_number(params[:number])
  end

  def place_order_to_oms
    begin
      order = Spree::Order.find(params[:id])
      oms_log = order.oms_log
      unless order.nil?
        resp = RestClient.post(OMS_PATH, :api_key => OMS_API_KEY, :order_bucket => order.get_order_bucket)
        resp = JSON.parse(resp)
        oms_log.update_attributes(:order_id => order.id, :oms_reference_number => resp["reference_id"], :oms_api_responce => resp["responce"], :oms_api_message => resp["message"])
        flash[:notice] = resp["message"]
        redirect_to oms_pending_admin_orders_path()
      else
        flash[:error] = "Order #{order.number} not found"
        redirect_to oms_pending_admin_orders_path()
      end
    rescue Exception => e
      flash[:error] = "Error: #{e.message}"
      redirect_to oms_pending_admin_orders_path()
    end
    return
  end
  
  # Dummy order form
  def generate_dummy_order
      @order = Spree::Order.new
  end
  
  # Create dummy order method
  def create_dummy_order
    mp = Spree::MarketPlace.find_by_code(params[:market_place])
    smp =  Spree::SellerMarketPlace.where(:seller_id => params[:seller_id], :market_place_id => mp.id).first
    if smp.present?
      code = smp.market_place.code
      case code
        when 'qoo10'
        when 'lazada','zalora'
          message = DummyOrderJob.create_dummy_order_for_lazada(params, smp)
      end
    else

    end
    render :json => {
               :message => message
           }
  end
private

end
