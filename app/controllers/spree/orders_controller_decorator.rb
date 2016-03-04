module Spree
	OrdersController.class_eval do

    def fetch_test_orders

      mp_code = 'lazada'
       order_number =Time.now.strftime("%d%m%y%s")
      skus = ['TPUSBM']
      qtys =  [2]
      mp = Spree::MarketPlace.find_by_code(mp_code)
      if mp.present?
        shpping_address = Spree::Address.create!(:firstname=>"Anchanto", :lastname=>"Pvt", :address1=>"Singapore", :address2=>"Singapore", :city=>"Singapore", :zipcode=>"12345", :phone=>"1234567890", :alternative_phone=>"1234567890", :country_id=>160, :state_name=>"Singapore")
        billing_address = Spree::Address.create!(:firstname=>"Anchanto", :lastname=>"Pvt", :address1=>"Singapore", :address2=>"Singapore", :city=>"Singapore", :zipcode=>"12345", :phone=>"1234567890", :alternative_phone=>"1234567890", :country_id=>160, :state_name=>"Singapore")
        order = Spree::Order.create!(:number=>order_number, :order_date=>Time.now(), :market_place_details=>"", :item_total=>51.00, :total=>51.00, :payment_total=>51.00, :email=>"anchanto@pvt.com", :currency=>'SGD', :send_as_gift=>false, :market_place_id=>mp.id, :seller_id=> 10, :market_place_order_no=>order_number, :market_place_order_status=>"Pending", :bill_address_id=>billing_address.id, :ship_address_id=>shpping_address.id, :cart_no=>order_number, :seller_id => 1)
        skus.each_with_index do |sku, index|
          variant = Spree::Variant.find_by_sku(sku)
          if variant.present?
            smp = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", variant.product.seller.id, mp.id).first
            mp_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", variant.product.seller_id, smp.market_place_id, variant.product_id).first
            if variant.product.kit.present?
              l_items = variant.product.kit.kit_products
              l_items.each do |lt|
                lt_variant = lt.variant
                line_item = Spree::LineItem.create!(:variant_id=>lt_variant.id, :order_id=>order.id, :quantity=>(lt.quantity*qtys[index]), :price=>51.00, :currency=>'SGD')
                lt_mp_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", variant.product.seller_id, smp.market_place_id, lt_variant.product_id)
                stock = lt_variant.product.stock_products.where("sellers_market_places_product_id IN (?)", lt_variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                stock.update_attributes!(:count_on_hand=>(stock.count_on_hand - (qtys[index]*lt.quantity)) >= 0 ? (stock.count_on_hand - (qtys[index]*lt.quantity)) : 0 ) if stock.present?
                lt_variant.update_attributes(:fba_quantity=>(lt_variant.fba_quantity - (qtys[index]*lt.quantity)))
                msg = 'Orders Controller fetch_test_orders Line 29'
                lt_variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
              end
            else
              line_item = Spree::LineItem.create!(:variant_id=>variant.id, :order_id=>order.id, :quantity=>qtys[index], :price=>51.00, :currency=>'SGD')
            end
            variant.update_attributes(:fba_quantity => (variant.fba_quantity-qtys[index]))
            msg = 'Orders Controller fetch_test_orders line 36'
            variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
            type = (STOCKCONFIG[variant.product.stock_config_type] == "default" ? STOCKCONFIG[variant.product.seller.stock_config_type] : STOCKCONFIG[variant.product.stock_config_type])
            if type != "flat_quantity"
              m_stock = variant.product.stock_products.where("sellers_market_places_product_id IN (?)", variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first rescue nil
              m_stock.update_attributes!(:count_on_hand=>(m_stock.count_on_hand - qtys[index]) >= 0 ? (m_stock.count_on_hand - qtys[index]) : 0 ) if m_stock.present?
            end
            ActiveSupport::Notifications.instrument('spree.order.contents_changed', {:user => nil, :order => order})
            Spree::Order.push_to_fba([order_number])
          else
            return sku+": Variant not found"
          end
        end
      else
        return "Market place not found"
      end
    end

    def populate
      populator = Spree::OrderPopulator.new(current_order(true), current_currency)
      if populator.populate(params.slice(:products, :variants, :quantity, :is_pickup, :stock_location))
        current_order.create_proposed_shipments if current_order.shipments.any?
        fire_event('spree.cart.add')
        fire_event('spree.order.contents_changed')
        respond_with(@order) do |format|
          format.html { redirect_to cart_path }
          format.js {render 'populate'}
        end
      else
        respond_with(@order) do |format|
          format.html { redirect_to :back }
          format.js {render 'error'}
        end
      end
    end

    # Callback url to update the order state in FBA
    def update_fulflmnt_state
       status = true
       message = ""
       my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
       @orders = Spree::Order.where("fulflmnt_tracking_no=? AND is_cancel=false", params[:event][:tracking_number])
       if @orders.present?
          @orders.each do |order|
            begin
              if order.update_attributes(:fulflmnt_state => params[:event][:new_state], :last_updated_date => Time.now)
                 case params[:event][:new_state]
                 when 'assign_for_pickup'
                   case order.market_place.code
                   when 'lazada','zalora'
                     message = Time.zone.now.to_s+" : "+order.cart_no.to_s+"-"+"FBA request for RTS"
                     my_logger.info(message)
                     @res = ApiJob.delay.order_state_to_rts_lazada(order.id)
                   end
                   message = Time.zone.now.to_s+" : Respose after RTS on MP "+order.market_place.name+"-"+order.cart_no.to_s+": "+@res.to_s
                   my_logger.info(message)
                 when 'picked_up'
                   @res = ApiJob.delay.order_state_to_rts_lazada(order.id) if order.market_place_order_status == "pending"
                 when 'packup'
                   case order.market_place.code
                   when 'lazada','zalora'
                     order.update_attributes!(:market_place_order_status=>"shipped")
                   end
                 when 'complete'
                   case order.market_place.code
                   when 'qoo10'
                     order.update_attributes!(:market_place_order_status=>"Delivered")
                   when 'lazada','zalora'
                     order.update_attributes!(:market_place_order_status=>"delivered")
                   end
                 when 'cancel'
                   case order.market_place.code
                   when 'qoo10','lazada','zalora'
                     order.update_attributes!(:cancel_on_fba => true, :market_place_order_status=>"cancel", :is_cancel=> true, :order_canceled_date=>(order.order_canceled_date.present? ? order.order_canceled_date : Time.now))
                   end
                 end # end of case
              end # end of if
            rescue Exception => e
              status = false
              message = order.market_place.name+"-"+order.market_place_order_no+": "+e.message
              my_logger.info(message)
            end
          end # end of loop
       else
         cancel_orders = Spree::Order.where("fulflmnt_tracking_no=? AND is_cancel=true", params[:event][:tracking_number])
         if cancel_orders.present?
           cancel_orders.update_all(:cancel_on_fba => true,:fulflmnt_state => "cancel")
         else
           status = false
           message = "Order state update failed"
         end

       end # end of order present if
       respond_to do |format|
         format.json { render :status => 200, :json => {:success => status.to_s, :message => message }}
       end
    end

    def change_order_state_qoo10(order)
      seller_id = order.seller_id.present? ? order.seller_id : nil
      @market_place = order.market_place
      muser = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", seller_id, order.market_place_id).first
      uri = URI(market_place.domain_url+'/ShippingBasicService.api/SetSendingInfo')
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data({'key'=>muser.api_secret_key,'OrderNo'=>order.market_place_order_no,'ShippingCorp'=>'Fulfillment By Anchanto','TrackingNo'=>order.fulflmnt_tracking_no})
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end
      return res.code == "200" ? "success" : "failed"
    end

    def show
      @order = Order.find_by_number!(params[:id])
      if session["view"] == "ios"
        render :layout => "ipad"
      end
    end

    def close_ios_view
      order = Order.find_by_number!(params[:id])
      if !order.nil? && order.completed?
        render :json => {:response => "success", :message => "Order Place has been placed successfully"}
      else
        render :json => {:response => "failure", :message => "Something went wrong, please check My Account"}
      end
      return
    end

    # method to sync the market place order and FBA - no used currently
    def order_sync
       @customer_pickup = nil
       @order = Spree::Order.find_by_number(params[:order])
       order = @order.market_place_details
       begin
       gift = order["Gift"].empty? ? false : true
       shipping_country = Spree::Country.find_by_iso(order["shippingCountry"])
       billing_country = Spree::Country.find_by_iso(order["senderNation"])
       name = order["receiver"].present? ? order["receiver"] : (order["buyer"].present? ? order["buyer"] : "NA")
       telno = order["receiverTel"].present? ? order["receiverTel"] : (order["buyerTel"].present? ? order["buyerTel"] : "NA")
       mobileno = order["receiverMobile"].present? ? order["receiverMobile"] : (order["buyerMobile"].present? ? order["buyerMobile"] : "NA")
       if order.present?
           if order["OrderType"] == "Pickup"
                  @customer_pickup = true
                   # Our Singapore warehouse address
                   address1 = "151 Pasir Panjang Road"
                   address2 = "#02-02 Pasir Panjang Distripark"
                   zipcode = "118480"
                   phone = "+65 6271 0524"
                   @order.shipping_address.update_attributes(:firstname=> name, :lastname=> name,
                                                                                          :address1=> address1, :address2=> address2,
                                                                                          :city=> shipping_country.name, :zipcode=> zipcode,
                                                                                          :phone=> phone, :alternative_phone=> "",
                                                                                          :country_id=> shipping_country.id, :state_name=> shipping_country.name)
                   if order[:Addr1].present?
                     @order.billing_address.update_attributes(:firstname=> name, :lastname=> name,
                                                                                        :address1=> order["Addr1"], :address2=> order["Addr2"],
                                                                                        :city=> shipping_country.name, :zipcode=> order["zipCode"],
                                                                                        :phone=> telno, :alternative_phone=> mobileno,
                                                                                        :country_id=> shipping_country.id, :state_name=> shipping_country.name)
                   end
           else
                     @customer_pickup = false
                     @order.shipping_address.update_attributes(:firstname=> name, :lastname=> name,
                                                                                          :address1=> order["Addr1"], :address2=> order["Addr2"],
                                                                                          :city=> shipping_country.name, :zipcode=> order["zipCode"],
                                                                                          :phone=> telno, :alternative_phone=> mobileno,
                                                                                          :country_id=> shipping_country.id, :state_name=> shipping_country.name)
           end

           if !order["senderName"].empty? && !order["senderAddr"].empty? && !order["senderNation"].empty? && !order["senderZipCode"].empty? && !order["senderTel"].empty? && !billing_country.nil?
              @order.billing_address.update_attributes(:first_name=> order["senderName"], :lastname=>"",
                                                                                 :address1=> order["senderAddr"], :address2=>"",
                                                                                 :city=> billing_country.name, :zipcode=> order["senderZipCode"],
                                                                                 :phone=> order["senderTel"], :alternative_phone=>"",
                                                                                 :country_id=> billing_country.id, :state_name=> billing_country.name)
           end
           billing_address = (!@order.billing_address.nil? && !@order.billing_address.blank?) ? @order.billing_address.id : nil
           @mp_product = nil
           @line_item = nil
           @stock = nil
           @mp_product = Spree::SellersMarketPlacesProduct.find_by_market_place_product_code(order["itemCode"])
           @order.update_attributes(:number=> order["orderNo"], :order_date=> order["orderDate"], :item_total=> order["orderPrice"],
                                                     :total=> order["total"], :payment_total=> order["total"],
                                                     :email=> order["buyerEmail"], :currency=> order["currency"],
                                                     :send_as_gift=> gift, :market_place_id=> @mp_product.market_place_id,
                                                     :market_place_order_no=> order["orderNo"],
                                                     :bill_address_id=> billing_address, :ship_address_id=> @order.shipping_address.id)
           @order.adjustments.first.update_attributes(:amount=> -order["discount"].to_f, :label=> "discount") if @order && @order.adjustments.present? && order["discount"].to_f != 0.0
            if @mp_product.present? && @order.present?
               if order["option"] == ""
                 # options not present
                 @variant = Spree::Variant.find_by_sku(@mp_product.product.sku)
                  if !@mp_product.nil? && !@mp_product.blank? && !@variant.nil? && !@variant.blank?
                      @line_item = Spree::LineItem.create!(:variant_id=> @variant.id, :order_id=> @order.id, :quantity=> order["orderQty"].to_i, :price=> order["orderPrice"], :currency=> order["Currency"], :is_pick_at_store => @customer_pickup)
                      @stock = @mp_product.product.stock_products.first
                  end
               else
                  # options are present
                  option_arr = order["option"].split("(")[0].split(":")
                  @variant = nil
                  @mp_product.product.variants.each do |v|
                      @variant = v if !v.option_values.blank? && (v.option_values.map(&:presentation).include?option_arr[1].strip)
                  end if !@mp_product.nil? && @mp_product.product && @mp_product.product.option_types && !@mp_product.product.option_types.blank? && (@mp_product.product.option_types.map(&:presentation).include?option_arr[0])
                  if !@mp_product.nil? && !@mp_product.blank? && !@variant.nil? && !@variant.blank?
                      @line_item = Spree::LineItem.create!(:variant_id=> @variant.id, :order_id=> @order.id, :quantity=> order["orderQty"].to_i, :price=> order["orderPrice"], :currency=> order["Currency"], :is_pick_at_store => @customer_pickup)
                      @stock = @mp_product.product.stock_products.where("variant_id=?", @variant.id).first
                  end
              end
               # to reduce the stock after placing the order
               @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - order["orderQty"].to_i) >= 0 ? (@stock.count_on_hand - order["orderQty"].to_i) : 0 ) if @stock
               # code to reduce the kit quantity after order placed for kit as product
               @product = @mp_product.product
                if @product.kit.present? && @product.present?
                   @product.kit.update_attributes(:quantity => @product.kit.quantity - order["orderQty"].to_i)
                end
                @order.reload
                # code to auto push order to FBA whenever order fulflmnt_tracking_no not present and order contains at-least 1 product
                if @order.line_items.present? && @order.fulflmnt_tracking_no.nil?
                    if @mp_product.present? && order.present?
                       smp = Spree::SellerMarketPlace.where(:seller_id => @mp_product.seller_id, :market_place_id => @mp_product.market_place_id).first
                       # check for customer pickup order or not
                       is_customer_pickup = (order["OrderType"] == "Pickup" ? true : false)
                       @order.push_to_fba(smp, is_customer_pickup)
                    end
                end
            end
       end
       rescue Exception => e
            puts e.message
       end
       redirect_to admin_order_url(@order), :notice => "Order synced successfully!"
    end

    # method to manual push order to FBA - no used currently
    def manual_push_order_to_fba
       @order = Spree::Order.find_by_number(params[:order])
       if @order.fulflmnt_tracking_no == nil
          @market_place = @order.market_place if @order.market_place.present?
          @seller = @order.seller
           smp = Spree::SellerMarketPlace.where("seller_id=? and market_place_id=? and is_active=?", @seller.id, @market_place.id, true).first
           if smp.present?
              if @order.market_place_details.present?
                  # check for customer pickup order or not
                  is_customer_pickup = (@order.market_place_details["OrderType"] == "Pickup" ? true : false)
                  @order.push_to_fba(smp, is_customer_pickup)
                  # last updated date for order
                  @order.update_attributes(:last_updated_date => Time.now)
                  oms_log = @order.oms_log
              end # end if market_place_details
           end # end if smp
       end # end if fulflmnt_tracking_no
       redirect_to admin_orders_path, :notice => "Order pushed to FBA successfully!"
    end

    # method to get the new order status in SF - no used currently
    def get_new_order_status
          @order = Spree::Order.find_by_number(params[:order])
          @market_place = @order.market_place if @order.market_place.present?
          @seller = @order.seller
           smp = Spree::SellerMarketPlace.where("seller_id=? and market_place_id=? and is_active=?", @seller.id, @market_place.id, true).try(:first)
           if smp.present?
              @order.get_order_status(smp)
              oms_log = @order.oms_log
           end
       redirect_to admin_order_url(@order), :notice => "Your Order #{@order.number} into #{@order.fulflmnt_state} state"
    end

    # method to cancel order on SF as well as on market place - no used currently
    def cancel
      @order = Spree::Order.find_by_number(params[:order])
      @message = ""
      @error = ""
      if @order.update_attributes(:is_cancel=>true)
        begin
          if @order.market_place.code == "qoo10"
            @message = cancel_order_qoo10(@order)
            @error = (@message == "failed") ? "Qoo10 order can not be canceled" : ""
          end
        rescue Exception => e
          @error = e.message
        end
        if @error.empty?
          flash[:message] = @message
        else
          @order.update_attributes(:is_cancel=>false)
          flash[:error] = @error
        end
      else
        flash[:error] = "Order can not be canceled"
      end
      redirect_to :back
    end

   # method to cancel order on CM as well as on market place (qoo10) - no used currently
    def cancel_order_qoo10(order)
      @error = ""
      @message = ""
      @order = order
      muser = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", @order.seller_id, @order.market_place_id).first
      market_place = order.market_place
      uri = URI(market_place.domain_url+'/ClaimAPIService.api/SetCancelProcess')
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data({'key'=>muser.api_secret_key,'ContrNo'=>@order.market_place_order_no})
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end
      if res.code == "200"
        #res_body = Hash.from_xml(res.body).to_json
        #res_body = JSON.parse(res_body, :symbolize_names=>true)
        seller_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @order.seller_id, @order.market_place_id, @order.products.first.id)
        if !seller_product.nil? && !seller_product.blank?
          # code to add the stock after cancelling the order
          if @order.line_items.present?
             @stock = seller_product.first.product.stock_products.where("variant_id=?", @order.line_items.first.variant.id).first
             @stock.update_attributes(:count_on_hand=> @stock.count_on_hand + @order.line_items.first.quantity) if @stock
          end
          @order.update_attributes!(:market_place_order_status => "cancel")
          # call api in FBA to cancel the order
          #@order.cancel_order_on_fba(muser)
        end
      else
        @error = "failed"
      end
      @message = "Order canceled successfully"
      return @error.empty? ? @message : @error
    end

    # To change state of lazada orders to ready to ship
            

    # To change state of lazada orders to shipped
    def order_state_to_shipped_lazada(order)
      @error_message = ""
      seller_id = order.seller_id.present? ? order.seller_id : nil
      smp = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", seller_id, order.market_place_id).first
      market_place = order.market_place
      Time.zone = "Singapore"
      current_time = Time.zone.now
      user_id = smp.contact_email ? smp.contact_email : "tejaswini.patil@anchanto.com"
      list_item_params = {"Action"=>"GetOrderItems", "OrderId"=>order.market_place_order_no, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
      signature_lt = view_context.generate_lazada_signature(list_item_params, smp)
      if signature_lt
        formed_list_item = []
        sorted_params_lt = Hash[list_item_params.sort]
        sorted_params_lt.merge!("Signature"=>signature_lt)
        sorted_params_lt.each do |key,value|formed_list_item << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
        param_string_lt = "?"+formed_list_item.join('&')
        uri_lt = URI.parse(market_place.domain_url+param_string_lt)
        http_lt = Net::HTTP.new(uri_lt.host, uri_lt.port)
        http_lt.use_ssl = true
        http_lt.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request_lt = Net::HTTP::Get.new(uri_lt.request_uri)
        res_lt = http_lt.request(request_lt)
        @order_item_ids = []
        if res_lt.code == "200"
          res_lt_body = Hash.from_xml(res_lt.body).to_json
          res_lt_body = JSON.parse(res_lt_body, :symbolize_names=>true)
          if res_lt_body[:SuccessResponse]
            @order_items = res_lt_body[:SuccessResponse][:Body][:OrderItems][:OrderItem]
            if @order_items.class == Hash
              @order_item_ids = @order_items[:OrderItemId]
            else
              @order_items.each do |item|
                @order_item_ids << item[:OrderItemId]
              end if @order_items
            end
          else
            @error_message = res_lt_body[:ErrorResponse][:Head][:ErrorMessage]
          end
        end
        @order_item_ids.each do |order_item|
          change_state_params = {"Action"=>"SetStatusToShipped", 'OrderItemId' => order_item.to_s, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
          signature = view_context.generate_lazada_signature(change_state_params, smp)
          if signature
            string_to_be_formed = []
            sorted_params = Hash[change_state_params.sort]
            sorted_params.merge!("Signature"=>signature)
            sorted_params.each do |key,value|string_to_be_formed << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
            param_string = "?"+string_to_be_formed.join('&')
            uri = URI.parse(market_place.domain_url+param_string)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            request = Net::HTTP::Get.new(uri.request_uri)
            res = http.request(request)
            if res.code != "200"
              res_body = Hash.from_xml(res.body).to_json
              res_body = JSON.parse(res_body, :symbolize_names=>true)
              if res_lt_body[:ErrorResponse]
                @error_message = res_lt_body[:ErrorResponse][:Head][:ErrorMessage]
              end
            end
          else
            @error_message = "Signature can not be generated"
          end
        end
      else
        @error_message = "Signature can not be generated"
      end
      return @error_message.empty? ? "success" : @error_message
    end

    # To chanage state for lazada for complete orders
    def order_state_to_complete_lazada(order)
      @error_message = ""
      seller_id = order.seller_id.present? ? order.seller_id : nil
      smp = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", seller_id, order.market_place_id).first
      market_place = order.market_place
      Time.zone = "Singapore"
      current_time = Time.zone.now
      user_id = smp.contact_email ? smp.contact_email : "tejaswini.patil@anchanto.com"
      list_item_params = {"Action"=>"GetOrderItems", "OrderId"=>order.market_place_order_no, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
      signature_lt = view_context.generate_lazada_signature(list_item_params, smp)
      if signature_lt
        formed_list_item = []
        sorted_params_lt = Hash[list_item_params.sort]
        sorted_params_lt.merge!("Signature"=>signature_lt)
        sorted_params_lt.each do |key,value|formed_list_item << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
        param_string_lt = "?"+formed_list_item.join('&')
        uri_lt = URI.parse(market_place.domain_url+param_string_lt)
        http_lt = Net::HTTP.new(uri_lt.host, uri_lt.port)
        http_lt.use_ssl = true
        http_lt.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request_lt = Net::HTTP::Get.new(uri_lt.request_uri)
        res_lt = http_lt.request(request_lt)
        @order_item_ids = []
        if res_lt.code == "200"
          res_lt_body = Hash.from_xml(res_lt.body).to_json
          res_lt_body = JSON.parse(res_lt_body, :symbolize_names=>true)
          if res_lt_body[:SuccessResponse]
            @order_items = res_lt_body[:SuccessResponse][:Body][:OrderItems][:OrderItem]
            if @order_items.class == Hash
              @order_item_ids = @order_items[:OrderItemId]
            else
              @order_items.each do |item|
                @order_item_ids << item[:OrderItemId]
              end if @order_items
            end
          else
            @error_message = res_lt_body[:ErrorResponse][:Head][:ErrorMessage]
          end
        end
        @order_item_ids.each do |order_item|
          change_state_params = {"Action"=>"SetStatusToDelivered", 'OrderItemId' => order_item.to_s, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
          signature = view_context.generate_lazada_signature(change_state_params, smp)
          if signature
            string_to_be_formed = []
            sorted_params = Hash[change_state_params.sort]
            sorted_params.merge!("Signature"=>signature)
            sorted_params.each do |key,value|string_to_be_formed << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
            param_string = "?"+string_to_be_formed.join('&')
            uri = URI.parse(market_place+param_string)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            request = Net::HTTP::Get.new(uri.request_uri)
            res = http.request(request)
            if res.code != "200"
              res_body = Hash.from_xml(res.body).to_json
              res_body = JSON.parse(res_body, :symbolize_names=>true)
              if res_lt_body[:ErrorResponse]
                @error_message = res_lt_body[:ErrorResponse][:Head][:ErrorMessage]
              end
            end
          else
            @error_message = "Signature can not be generated"
          end
        end
      else
        @error_message = "Signature can not be generated"
      end
      return @error_message.empty? ? "success" : @error_message
    end

    def cancel_order_lazada(order)
      @error_message = ""
      seller_id = order.seller_id.present? ? order.seller_id : nil
      smp = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", seller_id, order.market_place_id).first
      market_place = order.market_place
      Time.zone = "Singapore"
      current_time = Time.zone.now
      user_id = smp.contact_email ? smp.contact_email : "tejaswini.patil@anchanto.com"
      list_item_params = {"Action"=>"GetOrderItems", "OrderId"=>order.market_place_order_no, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
      signature_lt = view_context.generate_lazada_signature(list_item_params, smp)
      if signature_lt
        formed_list_item = []
        sorted_params_lt = Hash[list_item_params.sort]
        sorted_params_lt.merge!("Signature"=>signature_lt)
        sorted_params_lt.each do |key,value|formed_list_item << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
        param_string_lt = "?"+formed_list_item.join('&')
        uri_lt = URI.parse(market_place.domain_url+param_string_lt)
        http_lt = Net::HTTP.new(uri_lt.host, uri_lt.port)
        http_lt.use_ssl = true
        http_lt.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request_lt = Net::HTTP::Get.new(uri_lt.request_uri)
        res_lt = http_lt.request(request_lt)
        @order_item_ids = []
        if res_lt.code == "200"
          res_lt_body = Hash.from_xml(res_lt.body).to_json
          res_lt_body = JSON.parse(res_lt_body, :symbolize_names=>true)
          if res_lt_body[:SuccessResponse]
            @order_items = res_lt_body[:SuccessResponse][:Body][:OrderItems][:OrderItem]
            if @order_items.class == Hash
              @order_item_ids = @order_items[:OrderItemId]
            else
              @order_items.each do |item|
                @order_item_ids << item[:OrderItemId]
              end if @order_items
            end
          else
            @error_message = res_lt_body[:ErrorResponse][:Head][:ErrorMessage]
          end
        end
        @order_item_ids.each do |order_item|
          change_state_params = {"Action"=>"SetStatusToCanceled", 'OrderItemId' => order_item.to_s, 'Reason' => 'canceled', 'ReasonDetail' => '', "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
          signature = view_context.generate_lazada_signature(change_state_params, smp)
          if signature
            string_to_be_formed = []
            sorted_params = Hash[change_state_params.sort]
            sorted_params.merge!("Signature"=>signature)
            sorted_params.each do |key,value|string_to_be_formed << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
            param_string = "?"+string_to_be_formed.join('&')
            uri = URI.parse(market_place.domain_url+param_string)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            request = Net::HTTP::Get.new(uri.request_uri)
            res = http.request(request)
            if res.code != "200"
              res_body = Hash.from_xml(res.body).to_json
              res_body = JSON.parse(res_body, :symbolize_names=>true)
              if res_body[:ErrorResponse]
                @error_message = res_body[:ErrorResponse][:Head][:ErrorMessage]
              end
            end
          else
            @error_message = "Signature can not be generated"
          end
        end
      else
        @error_message = "Signature can not be generated"
      end
      return @error_message.empty? ? "success" : @error_message
    end
	end
end
