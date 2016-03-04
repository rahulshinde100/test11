module ApplicationHelper
  require 'openssl'
  require "base64"

  # Added by Abhijeet Ghude
  # To generate uniq signature key for Lazada API calls
  # This key is the combination of all request parameters encoded in RFC 3986 foramt in key value pair
  # Last modified on 14 Nov 2014
  def generate_lazada_signature(parameter_list, seller)
    api_key = seller.api_key
    #Sort parameter_list by key
    sorted_params = Hash[parameter_list.sort]
    string_to_be_formed = []
    # concatinate key value with
    sorted_params.each do |key,value|
      case key
      when "ShippingProvider"
        string_to_be_formed << CGI::escape("#{key}")+"="+URI::escape("#{value}")
      when "SkuSellerList"
        string_to_be_formed << CGI::escape("#{key}")+"="+CGI::escape("#{value}").gsub("+", "%20")
      else
        string_to_be_formed << CGI::escape("#{key}")+"="+CGI::escape("#{value}")
      end
    end
    singnature_string = string_to_be_formed.join('&')
    #Compute signature and add it to parameters
    signature_key = OpenSSL::HMAC.hexdigest('sha256', api_key, singnature_string)
    return signature_key
  end

  # Fetching order from Market place lazada
  def order_fetch_lazada(smp)
    @message = []
    @cart_numbers = []
    Time.zone = "Singapore"
    current_time = Time.zone.now
    orders_params = {"Action"=>"GetOrders", "CreatedAfter"=>(current_time.to_time-1.year).iso8601, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>smp.contact_email, "Version"=>"1.0"}
    signature = ApiJob.generate_lazada_signature(orders_params, smp)
    market_place = smp.market_place
    if signature
      string_to_be_formed = []
      sorted_params = Hash[orders_params.sort]
      sorted_params.merge!("Signature"=>signature)
      sorted_params.each do |key,value|string_to_be_formed << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
      param_string = "?"+string_to_be_formed.join('&')
      uri = URI.parse(market_place.domain_url+param_string)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      res = http.request(request)
      if res.code == "200"
        res_body = Hash.from_xml(res.body).to_json
        res_body = JSON.parse(res_body, :symbolize_names=>true)
        if res_body[:SuccessResponse] && res_body[:SuccessResponse][:Body][:Orders]
          @orders = []
          @orders << res_body[:SuccessResponse][:Body][:Orders][:Order]
          @orders = @orders.flatten
          begin
            @orders.each do |order|
            # {:OrderId=>"127250", :CustomerFirstName=>"JUNtest", :CustomerLastName=>"Lee", :OrderNumber=>"205373278", :PaymentMethod=>"CashOnDelivery", :Remarks=>nil, :DeliveryInfo=>nil, :Price=>"1497.00", :GiftOption=>"0", :GiftMessage=>nil, :VoucherCode=>nil, :CreatedAt=>"2015-12-08 15:20:03", :UpdatedAt=>"2015-12-14 17:20:13",
              # :AddressBilling=>{:FirstName=>"JUNtest", :LastName=>"Lee", :Phone=>"94331273", :Phone2=>"94331273", :Address1=>"Blk 602 B Punggol Central", :Address2=>"#04-666", :Address3=>nil, :Address4=>nil, :Address5=>nil, :City=>"Singapore", :Ward=>nil, :Region=>nil, :PostCode=>"822602", :Country=>"Singapore"},
              # :AddressShipping=>{:FirstName=>"JUNtest", :LastName=>"Lee", :Phone=>"94331273", :Phone2=>"94331273", :Address1=>"Blk 602 B Punggol Central", :Address2=>"#04-666", :Address3=>nil, :Address4=>nil, :Address5=>nil, :City=>"Singapore", :Ward=>nil, :Region=>nil, :PostCode=>"822602", :Country=>"Singapore"},
              # :NationalRegistrationNumber=>nil, :ItemsCount=>"3", :PromisedShippingTime=>nil, :Statuses=>{:Status=>"ready_to_ship"}}
            # order = @orders.first
              message = create_order_for_lazada(order, smp)
              @message << order[:OrderNumber].to_s+"-"+message.to_s if message != true
            end if @orders.present? # End for Order loop
          rescue Exception => e
            @message << e.message
          end
        else
          @message << "API call failed"
        end
      end # End for the order fetch response check
    end # End for order fetch signature check
    @cart_numbers = @cart_numbers.uniq
    @message << "FBA: "+ Spree::Order.push_to_fba(@cart_numbers) if @cart_numbers.present?
    @message << fetch_invoice_from_lazada(smp)
    return @message.join("; ")
  end

  # Create order on order fetch from lazada
  def create_order_for_lazada(order, smp)
    @order_items = []
    @order = nil
    @order_status = nil
    message = ""
    cm_user = smp.seller.is_cm_user
    begin
      # List item fetch from order API
      @order = Spree::Order.where("market_place_order_no=? AND seller_id=?", order[:OrderId], smp.seller_id).try(:first)
      if !@order.present?
        p '----------'
        Time.zone = "Singapore"
        current_time = Time.zone.now
        list_item_params = {"Action"=>"GetOrderItems", "OrderId"=>order[:OrderId], "Timestamp"=>current_time.to_time.iso8601, "UserID"=>smp.contact_email, "Version"=>"1.0"}
        signature_lt = generate_lazada_signature(list_item_params, smp)
        market_place = smp.market_place
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
          if res_lt.code == "200"
            res_lt_body = Hash.from_xml(res_lt.body).to_json
            res_lt_body = JSON.parse(res_lt_body, :symbolize_names=>true)
            @order_items << res_lt_body[:SuccessResponse][:Body][:OrderItems][:OrderItem]
            @order_items = @order_items.flatten
            @order_status = @order_items[0][:Status]
            gift = (order[:GiftOption] == "0" ? false : true)
            shipping_country = Spree::Country.find_by_name(order[:AddressShipping][:Country])
            billing_country = Spree::Country.find_by_name(order[:AddressBilling][:Country])
            shipping_last_name = (order[:AddressShipping][:LastName] ? order[:AddressShipping][:LastName] : order[:AddressShipping][:FirstName])
            billing_last_name = (order[:AddressBilling][:LastName] ? order[:AddressBilling][:LastName] : order[:AddressBilling][:FirstName])
            shipping_phone_no = (order[:AddressShipping][:Phone].present? ? order[:AddressShipping][:Phone] : order[:AddressShipping][:Phone2])
            billing_phone_no = (order[:AddressBilling][:Phone].present? ? order[:AddressBilling][:Phone] : order[:AddressBilling][:Phone2])
            @shpping_address = Spree::Address.create!(:firstname=>order[:AddressShipping][:FirstName], :lastname=>shipping_last_name, :address1=>order[:AddressShipping][:Address1], :address2=>order[:AddressShipping][:Address2], :city=>shipping_country.name, :zipcode=>order[:AddressShipping][:PostCode], :phone=>shipping_phone_no, :alternative_phone=>order[:AddressShipping][:Phone2], :country_id=>shipping_country.id, :state_name=>shipping_country.name)
            if !order[:AddressBilling][:FirstName].present? && !order[:AddressBilling][:Address1].present? && !order[:AddressBilling][:Country].present? && !order[:AddressBilling][:PostCode].present? && !order[:AddressBilling][:Phone].present? && !billing_country.nil?
              @billing_address = Spree::Address.create!(:firstname=>order[:AddressBilling][:FirstName], :lastname=>billing_last_name, :address1=>order[:AddressBilling][:Address1], :address2=>order[:AddressBilling][:Address2], :city=>billing_country.name,:zipcode=>order[:AddressBilling][:PostCode], :phone=>billing_phone_no, :alternative_phone=>order[:AddressBilling][:Phone2], :country_id=>billing_country.id, :state_name=>billing_country.name)
            end
            billing_address = (!@billing_address.nil? && !@billing_address.blank?) ? @billing_address.id : nil
            order_item_list = []
            item_total = 0.0
            payment_total = 0.0
            quantity_hash = {}
            price_hash = {}
              @order_items.each do |item|
                # item[:Sku] = 'NEWRKIT'#'TPUSBC'#'NEWRKIT'
                item_total = item_total + item[:ItemPrice].to_f
                payment_total = payment_total + item[:PaidPrice].to_f
                if price_hash[item[:Sku]].present?
                  price_hash[item[:Sku]] = price_hash[item[:Sku]].to_f + item[:PaidPrice].to_f
                else 
                  price_hash = price_hash.merge(item[:Sku]=>item[:PaidPrice].to_f) 
                end
                if quantity_hash[item[:Sku]].present?
                  quantity_hash[item[:Sku]] = quantity_hash[item[:Sku]].to_i + 1
                else
                  quantity_hash = quantity_hash.merge(item[:Sku]=>1)
                  order_item_list << item
                end
              end
            currency = (order_item_list.present? ? order_item_list.first[:Currency] : "SGD")
            @order = Spree::Order.create!(:number=>order[:OrderNumber], :order_date=>order[:CreatedAt], :market_place_details=>order, :item_total=>item_total, :total=>payment_total, :payment_total=>payment_total, :email=>smp.seller.contact_person_email, :currency=>currency, :send_as_gift=>gift, :market_place_id=>smp.market_place_id, :market_place_order_no=>order[:OrderId], :market_place_order_status=>@order_status, :bill_address_id=>billing_address, :ship_address_id=> @shpping_address.id, :cart_no=>order[:OrderNumber], :seller_id=>smp.seller_id, :is_bypass=>!cm_user)
            p @order
            order_item_list.each do |item|
              if cm_user
                # item[:Sku] ='NEWRKIT'# 'TPUSBC'#
                @variant = nil
                @mp_product = nil
                @line_item = nil
                @stock = nil
                @variant = Spree::Variant.includes(:product).where("spree_products.seller_id=? AND sku=?", smp.seller_id, item[:Sku]).try(:first)
                if @variant.present?
                  @mp_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @variant.product.seller_id, smp.market_place_id, @variant.product_id).first
                  if @variant.product.kit.present?
                    kit = @variant.product.kit
                    l_items = kit.kit_products
                    l_items.each do |lt|
                      lt_variant = lt.variant
                      quantity = lt.quantity*quantity_hash[item[:Sku]]
                      line_item = Spree::LineItem.create!(:variant_id=>lt_variant.id, :order_id=>@order.id, :quantity=>quantity, :price=>(lt_variant.price*quantity), :currency=>item[:Currency], :kit_id=>kit.id, :rcp=>price_hash[item[:Sku]])
                      stock = lt_variant.stock_products.where("sellers_market_places_product_id IN (?)", lt_variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                      lt_variant.update_attributes(:fba_quantity=>(lt_variant.fba_quantity - quantity)) if !lt_variant.quantity_inflations.present?
                      msg = 'Application Helper Create Order Lazada'
                      lt_variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
                      stock.update_attributes!(:count_on_hand=>(stock.count_on_hand - quantity) >= 0 ? (stock.count_on_hand - quantity) : 0 ) if stock.present? && lt_variant.quantity_inflations.present?
                    end
                  else
                    if @variant.parent_id.present?
                      @parent =  Spree::Variant.find(@variant.parent_id)
                      if @parent.product.kit.present?
                        kit = @parent.product.kit
                        l_items = kit.kit_products
                        l_items.each do |lt|
                          lt_variant = lt.variant
                          quantity = lt.quantity*quantity_hash[item[:Sku]]
                          line_item = Spree::LineItem.create!(:variant_id=>lt_variant.id, :order_id=>@order.id, :quantity=>quantity, :price=>(lt_variant.price*quantity), :currency=>item[:Currency], :kit_id=>kit.id, :rcp=>price_hash[item[:Sku]])
                          stock = lt_variant.stock_products.where("sellers_market_places_product_id IN (?)", lt_variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                          lt_variant.update_attributes(:fba_quantity=>(lt_variant.fba_quantity - quantity)) if !lt_variant.quantity_inflations.present?
                          stock.update_attributes!(:count_on_hand=>(stock.count_on_hand - quantity) >= 0 ? (stock.count_on_hand - quantity) : 0 ) if @stock.present? && lt_variant.quantity_inflations.present?
                          msg = 'Application Helper Create Order Lazada Family Kit If'
                          lt_variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                        end
                      else
                        @line_item = Spree::LineItem.create!(:variant_id=>@parent.id, :order_id=>@order.id, :quantity=>quantity_hash[item[:Sku]], :price=>item[:PaidPrice], :currency=>item[:Currency], :rcp=>price_hash[item[:Sku]])
                        type = (STOCKCONFIG[@parent.product.stock_config_type] == "default" ? STOCKCONFIG[@parent.product.seller.stock_config_type] : STOCKCONFIG[@parent.product.stock_config_type])
                        @parent.update_attributes(:fba_quantity=>(@parent.fba_quantity - quantity_hash[item[:Sku]])) if !@parent.quantity_inflations.present?
                        msg = 'Application Helper Create Order Lazada Parent Family Kit Else'
                        @parent.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                        @variant.update_attributes(:fba_quantity=>(@parent.fba_quantity - quantity_hash[item[:Sku]])) if (!@variant.quantity_inflations.present? && @parent.quantity_inflations.present?)
                        msg = 'Application Helper Create Order Lazada Family Kit Else'
                        @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                        if (type != "flat_quantity") || (type == "flat_quantity" && !@parent.product.kit.present?)
                          @stock = @parent.stock_products.where("sellers_market_places_product_id IN (?)", @parent.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                          @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - quantity_hash[item[:Sku]]) >= 0 ? (@stock.count_on_hand - quantity_hash[item[:Sku]]) : 0 ) if @stock.present? && @parent.quantity_inflations.present?
                        end
                        child_type = (STOCKCONFIG[@variant.product.stock_config_type] == "default" ? STOCKCONFIG[@variant.product.seller.stock_config_type] : STOCKCONFIG[@variant.product.stock_config_type])
                        if (child_type != "flat_quantity") || (child_type == "flat_quantity" && !@variant.product.kit.present?)
                          @stock = @variant.stock_products.where("sellers_market_places_product_id IN (?)", @variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                          @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - quantity_hash[item[:Sku]]) >= 0 ? (@stock.count_on_hand - quantity_hash[item[:Sku]]) : 0 ) if @stock.present? && @variant.quantity_inflations.present?
                        end
                      end
                    else
                      @line_item = Spree::LineItem.create!(:variant_id=>@variant.id, :order_id=>@order.id, :quantity=>quantity_hash[item[:Sku]], :price=>item[:PaidPrice], :currency=>item[:Currency], :rcp=>price_hash[item[:Sku]]) 
                      type = (STOCKCONFIG[@variant.product.stock_config_type] == "default" ? STOCKCONFIG[@variant.product.seller.stock_config_type] : STOCKCONFIG[@variant.product.stock_config_type])
                      @variant.update_attributes(:fba_quantity=>(@variant.fba_quantity - quantity_hash[item[:Sku]])) if !@variant.quantity_inflations.present?
                      msg = 'Application Helper Create Order Lazada Without Family'
                      @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                      if (type != "flat_quantity") || (type == "flat_quantity" && !@variant.product.kit.present?)
                        @stock = @variant.stock_products.where("sellers_market_places_product_id IN (?)", @variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                        @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - quantity_hash[item[:Sku]]) >= 0 ? (@stock.count_on_hand - quantity_hash[item[:Sku]]) : 0 ) if @stock.present? && @variant.quantity_inflations.present?
                      end
                    end
                  end
                end
              else
                Spree::MpOrderLineItem.create!(:order_id=>@order.id, :market_place_details=>item)
              end
            end # end of order_item_list
            @order.update_column(:total, payment_total)
            @order.reload
            ActiveSupport::Notifications.instrument('spree.order.contents_changed', {:user => nil, :order => @order})
            @cart_numbers << order[:OrderNumber]
          else # else for order check condition
            if @order.market_place_order_status != @order_status
               @order.update_attributes(:market_place_order_status=>@order_status)
            end
          end
        end # End for item list response check

      end # End of item list signature check
    rescue Exception => e
      message << e.message
    end
    return message.length > 0 ? message : true
  end

  # Fetching order from Market place qoo10
  def order_fetch_qoo10(smp)
    @message = []
    @cart_numbers = []
    cm_user = smp.seller.is_cm_user
    #qoo10_statuses = {"1"=>"Waiting for Shipping", "2"=>"Request Shipping", "3"=>"Check Order"}
    qoo10_statuses = {"2"=>"Request Shipping", "3"=>"Check Order"}
    market_place = Spree::MarketPlace.find(smp.market_place_id)
    qoo10_statuses.keys.each do |k|
      uri = URI(market_place.domain_url+'/ShippingBasicService.api/GetShippingInfo')
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data({'key'=>smp.api_secret_key,'ShippingStat'=>k,'search_Sdate'=>'','search_Edate'=>''})
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req) end
      if res.code == "200"
        begin
          res_body = Hash.from_xml(res.body).to_json
          res_body = JSON.parse(res_body, :symbolize_names=>true)
          if res_body[:ShippingAPIService][:ResultMsg] == "Success"
            for i in 1..res_body[:ShippingAPIService][:TotalOrder].to_i
              begin
                @order = nil
                order = res_body[:ShippingAPIService][("Order"+i.to_s).to_sym]
                @order = Spree::Order.where("market_place_order_no=? AND seller_id=?", order[:orderNo], smp.seller_id).try(:first)
                @shpping_address = nil
                @billing_address = nil
                @is_customer_pickup = nil
                if !@order.present?
                  gift = order[:Gift].present? ? false : true
                  shipping_country = Spree::Country.find_by_iso(order[:shippingCountry])
                  billing_country = Spree::Country.find_by_iso(order[:senderNation])
                  name = order[:receiver].present? ? order[:receiver] : (order[:buyer].present? ? order[:buyer] : "NA")
                  telno = order[:receiverTel].present? ? order[:receiverTel] : (order[:buyerTel].present? ? order[:buyerTel] : "NA")
                  mobileno = order[:receiverMobile].present? ? order[:receiverMobile] : (order[:buyerMobile].present? ? order[:buyerMobile] : "NA")
                  if order[:OrderType] == "Pickup"
                    @is_customer_pickup = true
                    # Our Singapore warehouse address
                    address1 = "151 Pasir Panjang Road"
                    address2 = "#02-02 Pasir Panjang Distripark"
                    zipcode = "118480"
                    phone = "+65 6271 0524"
                    @shpping_address = Spree::Address.create!(:firstname=>name, :lastname=>name, :address1=>address1, :address2=>address2, :city=>shipping_country.name, :zipcode=>zipcode, :phone=>phone, :alternative_phone=>"", :country_id=>shipping_country.id, :state_name=>shipping_country.name)
                    if order[:Addr1].present?
                      @billing_address = Spree::Address.create!(:firstname=>name, :lastname=>name, :address1=>order[:Addr1], :address2=>order[:Addr2], :city=>shipping_country.name, :zipcode=>order[:zipCode], :phone=>telno, :alternative_phone=>mobileno, :country_id=>shipping_country.id, :state_name=>shipping_country.name)
                    end
                  else
                    @is_customer_pickup = false
                    @shpping_address = Spree::Address.create!(:firstname=>name, :lastname=>name, :address1=>order[:Addr1], :address2=>order[:Addr2], :city=>shipping_country.name, :zipcode=>order[:zipCode], :phone=>telno, :alternative_phone=>mobileno, :country_id=>shipping_country.id, :state_name=>shipping_country.name)
                  end
                  if !order[:senderName].present? && !order[:senderAddr].present? && !order[:senderNation].present? && !order[:senderZipCode].present? && !order[:senderTel].present? && !billing_country.nil?
                    @billing_address = Spree::Address.create!(:firstname=>order[:senderName], :lastname=>order[:senderName], :address1=>order[:senderAddr], :address2=>"", :city=>billing_country.name,
                      :zipcode=>order[:senderZipCode], :phone=>order[:senderTel], :alternative_phone=>"", :country_id=>billing_country.id, :state_name=>billing_country.name)
                  end
                  billing_address = (!@billing_address.nil? && !@billing_address.blank?) ? @billing_address.id : nil
                  if @shpping_address.present?
                    @order = Spree::Order.create!(:number=>order[:orderNo], :order_date=> order[:PaymentDate], :market_place_details=>order, :item_total=>order[:orderPrice], :total=>order[:total].to_f, :payment_total=>order[:total], :email=>order[:buyerEmail], :currency=>order[:Currency], :send_as_gift=>gift, :market_place_id=>smp.market_place_id, :market_place_order_no=>order[:orderNo], :market_place_order_status=>qoo10_statuses[k], :bill_address_id=>billing_address, :ship_address_id=> @shpping_address.id, :cart_no=> order[:packNo], :seller_id=>smp.seller_id, :is_bypass=>!cm_user)
                  else
                    @message <<  order[:orderNo]+": "+ "Ooops..Shipping address is missing"
                  end
                  if cm_user
                    @mp_product = nil
                    @mp_product = Spree::SellersMarketPlacesProduct.find_by_market_place_product_code(order[:itemCode])
                    if @order.present?
                      if order[:option] == ""
                        @variant = Spree::Variant.includes(:product).where("spree_products.seller_id=? AND sku=?", smp.seller_id, order[:sellerItemCode]).try(:first) if order[:sellerItemCode].present?
                        @variant = Spree::Variant.find_by_sku(@mp_product.product.sku) if !@variant.present? && @mp_product.present? 
                        if @variant.present? && @variant.product.kit.present?
                          kit = @variant.product.kit
                          l_items = kit.kit_products
                          l_items.each do |lt|
                            lt_variant = lt.variant
                            quantity = lt.quantity*order[:orderQty].to_i
                            line_item = Spree::LineItem.create!(:variant_id=>lt_variant.id, :order_id=>@order.id, :quantity=>quantity, :price=>(lt_variant.price*quantity), :currency=>order[:Currency], :is_pick_at_store => @is_customer_pickup, :kit_id=>kit.id, :rcp=>order[:total])
                            stock = lt_variant.product.stock_products.where("sellers_market_places_product_id IN (?)", lt_variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                            lt_variant.update_attributes(:fba_quantity=>(lt_variant.fba_quantity - quantity)) if !lt_variant.quantity_inflations.present?
                            msg = 'Application Helper fetch Qoo10 Variant Kit 003'
                            @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                            stock.update_attributes!(:count_on_hand=>((stock.count_on_hand - quantity) >= 0 ? (stock.count_on_hand - quantity) : 0 )) if stock.present? && lt_variant.quantity_inflations.present?
                          end
                        elsif @variant.present?
                          if @variant.parent_id.present?
                            @parent =  Spree::Variant.find(@variant.parent_id)
                            if @parent.product.kit.present?
                              kit = @parent.product.kit
                              l_items = kit.kit_products
                              l_items.each do |lt|
                                lt_variant = lt.variant
                                quantity = lt.quantity*order[:orderQty].to_i
                                line_item = Spree::LineItem.create!(:variant_id=>lt_variant.id, :order_id=>@order.id, :quantity=>quantity, :price=>(lt_variant.price*quantity), :currency=>order[:Currency], :is_pick_at_store => @is_customer_pickup, :kit_id=>kit.id, :rcp=>order[:total])
                                stock = lt_variant.product.stock_products.where("sellers_market_places_product_id IN (?)", lt_variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                                lt_variant.update_attributes(:fba_quantity=>(lt_variant.fba_quantity - quantity)) if !lt_variant.quantity_inflations.present?
                                msg = 'Application Helper fetch Qoo10 Variant Family 002'
                                @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                                stock.update_attributes!(:count_on_hand=>((stock.count_on_hand - quantity) >= 0 ? (stock.count_on_hand - quantity) : 0 )) if stock.present? && lt_variant.quantity_inflations.present?
                              end
                            else
                              @line_item = Spree::LineItem.create!(:variant_id=>@parent.id, :order_id=>@order.id, :quantity=>order[:orderQty].to_i, :price=>order[:orderPrice], :currency=>order[:Currency], :is_pick_at_store => @is_customer_pickup, :rcp=>order[:total])
                              type = (STOCKCONFIG[@parent.product.stock_config_type] == "default" ? STOCKCONFIG[@parent.product.seller.stock_config_type] : STOCKCONFIG[@parent.product.stock_config_type])
                              @parent.update_attributes(:fba_quantity=>(@parent.fba_quantity - order[:orderQty].to_i)) if !@parent.quantity_inflations.present?
                              msg = 'Application Helper fetch Qoo10 parent Family kit 001'
                              @parent.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                              @variant.update_attributes(:fba_quantity=>(@variant.fba_quantity - order[:orderQty].to_i)) if !@variant.quantity_inflations.present? && @parent.quantity_inflations.present?
                              msg = 'Application Helper fetch Qoo10 Family Kit 001'
                              @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                              if (type != "flat_quantity") || (type == "flat_quantity" && !@parent.product.kit.present?)
                                @stock = @parent.stock_products.where("sellers_market_places_product_id IN (?)", @parent.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                                @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - order[:orderQty].to_i) >= 0 ? (@stock.count_on_hand - order[:orderQty].to_i) : 0 ) if @stock.present? && @parent.quantity_inflations.present?
                              end
                              child_type = (STOCKCONFIG[@variant.product.stock_config_type] == "default" ? STOCKCONFIG[@variant.product.seller.stock_config_type] : STOCKCONFIG[@variant.product.stock_config_type])
                              if (child_type != "flat_quantity") || (child_type == "flat_quantity" && !@variant.product.kit.present?)
                                @stock = @variant.stock_products.where("sellers_market_places_product_id IN (?)", @variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).try(:first)
                                @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - order[:orderQty].to_i) >= 0 ? (@stock.count_on_hand - order[:orderQty].to_i) : 0 ) if @stock.present? && (@parent.quantity_inflations.present? || @variant.quantity_inflations.present?)
                              end
                            end
                          else
                            @line_item = Spree::LineItem.create!(:variant_id=>@variant.id, :order_id=>@order.id, :quantity=>order[:orderQty].to_i, :price=>order[:orderPrice], :currency=>order[:Currency], :is_pick_at_store => @is_customer_pickup, :rcp=>order[:total])
                            type = (STOCKCONFIG[@variant.product.stock_config_type] == "default" ? STOCKCONFIG[@variant.product.seller.stock_config_type] : STOCKCONFIG[@variant.product.stock_config_type])
                            @variant.update_attributes(:fba_quantity=>(@variant.fba_quantity - order[:orderQty].to_i)) if !@variant.quantity_inflations.present?
                            msg = 'Application Helper fetch Qoo10 Family Only Variant Else'
                            @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                            if (type != "flat_quantity") || (type == "flat_quantity" && !@variant.product.kit.present?)
                              @stock = @variant.stock_products.where("sellers_market_places_product_id IN (?)", @variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                              @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - order[:orderQty].to_i) >= 0 ? (@stock.count_on_hand - order[:orderQty].to_i) : 0 ) if @stock.present? && @variant.quantity_inflations.present?
                            end
                          end
                        end
                      else
                        option_code_count = 1
                        option_codes = []
                        if order[:optionCode] == "" || !order[:optionCode].present?
                          option_arr = order[:option].split(":")
                          if option_arr[1].split("(+").count > 1
                            option_arr[1] = option_arr[1].split("(+")[0]
                          elsif option_arr[1].split("(-").count > 1
                            option_arr[1] = option_arr[1].split("(-")[0]
                          end
                          @variant = nil
                          @mp_product.product.variants.each do |v|
                            @variant = v if !v.option_values.blank? && (v.option_values.map(&:presentation).include?option_arr[1].strip)
                            option_codes = [@variant.sku] if @variant.present?
                          end if @mp_product.present? && @mp_product.product && @mp_product.product.option_types && @mp_product.product.option_types.present? && (@mp_product.product.option_types.map(&:presentation).include?option_arr[0])
                        else
                          option_codes = order[:optionCode].to_s.split(",")
                          option_code_count = option_codes.length
                        end
                        for j in 0..(option_code_count - 1)
                          @line_item = nil
                          @stock = nil
                          @variant = nil
                          @variant = Spree::Variant.includes(:product).where("spree_products.seller_id=? AND sku=?", smp.seller_id, option_codes[j]).try(:first) if order[:sellerItemCode].present?
                          @variant = @mp_product.product.variants_including_master.find_by_sku(option_codes[j]) if !@variant.present? && @mp_product.present?
                          if @variant.present?
                            if @variant.product.kit.present?
                              kit = @variant.product.kit
                              l_items = kit.kit_products
                              l_items.each do |lt|
                                lt_variant = lt.variant
                                quantity = lt.quantity*order[:orderQty].to_i
                                line_item = Spree::LineItem.create!(:variant_id=>lt_variant.id, :order_id=>@order.id, :quantity=>quantity, :price=>(lt_variant.price*quantity), :currency=>order[:Currency], :is_pick_at_store => @is_customer_pickup, :kit_id=>kit.id, :rcp=>(order[:total].to_f/option_code_count))
                                stock = lt_variant.stock_products.where("sellers_market_places_product_id IN (?)", lt_variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).try(:first)
                                lt_variant.update_attributes(:fba_quantity=>(lt_variant.fba_quantity - quantity)) if !lt_variant.quantity_inflations.present?
                                msg = 'Application Helper fetch Qoo10 Only Kit If'
                                lt_variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                                stock.update_attributes!(:count_on_hand=>(stock.count_on_hand - quantity) >= 0 ? (stock.count_on_hand - quantity) : 0 ) if stock.present? && lt_variant.quantity_inflations.present?
                              end
                            else
                              if @variant.parent_id.present?
                                @parent =  Spree::Variant.find(@variant.parent_id)
                                # @line_item = Spree::LineItem.create!(:variant_id=>@parent.id, :order_id=>@order.id, :quantity=>order[:orderQty].to_i, :price=>order[:orderPrice], :currency=>order[:Currency], :is_pick_at_store => @is_customer_pickup)
                                if @parent.product.kit.present?
                                  l_items = @parent.product.kit.kit_products
                                  l_items.each do |lt|
                                    lt_variant = lt.variant
                                    quantity = lt.quantity*order[:orderQty].to_i
                                    line_item = Spree::LineItem.create!(:variant_id=>lt_variant.id, :order_id=>@order.id, :quantity=>quantity, :price=>(lt_variant.price*quantity), :currency=>order[:Currency], :is_pick_at_store => @is_customer_pickup, :kit_id=>kit.id, :rcp=>(order[:total].to_f/option_code_count))
                                    stock = lt_variant.product.stock_products.where("sellers_market_places_product_id IN (?)", lt_variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                                    lt_variant.update_attributes(:fba_quantity=>(lt_variant.fba_quantity - quantity)) if !lt_variant.quantity_inflations.present?
                                    msg = 'Application Helper fetch Qoo10 Family Kit If'
                                    lt_variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                                    stock.update_attributes!(:count_on_hand=>((stock.count_on_hand - quantity) >= 0 ? (stock.count_on_hand - quantity) : 0 )) if stock.present? && lt_variant.quantity_inflations.present?
                                  end
                                else
                                  @line_item = Spree::LineItem.create!(:variant_id=>@parent.id, :order_id=>@order.id, :quantity=>order[:orderQty].to_i, :price=>order[:orderPrice], :currency=>order[:Currency], :is_pick_at_store => @is_customer_pickup, :rcp=>(order[:total].to_f/option_code_count))
                                  type = (STOCKCONFIG[@parent.product.stock_config_type] == "default" ? STOCKCONFIG[@parent.product.seller.stock_config_type] : STOCKCONFIG[@parent.product.stock_config_type])
                                  @parent.update_attributes(:fba_quantity=>(@parent.fba_quantity - order[:orderQty].to_i)) if !@parent.quantity_inflations.present?
                                  msg = 'Application Helper fetch Qoo10 Parent Family Kit Else'
                                  @parent.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                                  @variant.update_attributes(:fba_quantity=>(@variant.fba_quantity - order[:orderQty].to_i)) if !@variant.quantity_inflations.present? && @parent.quantity_inflations.present?
                                  msg = 'Application Helper fetch Qoo10 Family Kit Else'
                                  @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                                  if (type != "flat_quantity") || (type == "flat_quantity" && !@parent.product.kit.present?)
                                    @stock = @parent.stock_products.where("sellers_market_places_product_id IN (?)", @parent.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                                    @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - order[:orderQty].to_i) >= 0 ? (@stock.count_on_hand - order[:orderQty].to_i) : 0 ) if @stock.present? && @parent.quantity_inflations.present?
                                  end
                                  child_type = (STOCKCONFIG[@variant.product.stock_config_type] == "default" ? STOCKCONFIG[@variant.product.seller.stock_config_type] : STOCKCONFIG[@variant.product.stock_config_type])
                                  if (child_type != "flat_quantity") || (child_type == "flat_quantity" && !@variant.product.kit.present?)
                                    @stock = @variant.stock_products.where("sellers_market_places_product_id IN (?)", @variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                                    @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - order[:orderQty].to_i) >= 0 ? (@stock.count_on_hand - order[:orderQty].to_i) : 0 ) if @stock.present? && (@parent.quantity_inflations.present? && @variant.quantity_inflations.present?)
                                  end
                                end
                              else
                                @line_item = Spree::LineItem.create!(:variant_id=>@variant.id, :order_id=>@order.id, :quantity=>order[:orderQty].to_i, :price=>order[:orderPrice], :currency=>order[:Currency], :is_pick_at_store => @is_customer_pickup, :rcp=>(order[:total].to_f/option_code_count))
                                type = (STOCKCONFIG[@variant.product.stock_config_type] == "default" ? STOCKCONFIG[@variant.product.seller.stock_config_type] : STOCKCONFIG[@variant.product.stock_config_type])
                                @variant.update_attributes(:fba_quantity=>(@variant.fba_quantity - order[:orderQty].to_i)) if !@variant.quantity_inflations.present?
                                msg = 'Application Helper fetch Qoo10 without Family Else'
                                @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"

                                if (type != "flat_quantity") || (type == "flat_quantity" && !@variant.product.kit.present?)
                                  @stock = @variant.stock_products.where("sellers_market_places_product_id IN (?)", @variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                                  @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - order[:orderQty].to_i) >= 0 ? (@stock.count_on_hand - order[:orderQty].to_i) : 0 ) if @stock.present? && @variant.quantity_inflations.present?
                                end
                              end

                            end
                          end
                          # if @variant.parent_id.present?
                          #   @parent =  Spree::Variant.find(@variant.parent_id)
                          #   type = (STOCKCONFIG[@parent.product.stock_config_type] == "default" ? STOCKCONFIG[@parent.product.seller.stock_config_type] : STOCKCONFIG[@parent.product.stock_config_type])
                          #   @parent.update_attributes(:fba_quantity=>(@parent.fba_quantity - order[:orderQty].to_i)) if !@parent.quantity_inflations.present?
                          #   if (type != "flat_quantity") || (type == "flat_quantity" && !@parent.product.kit.present?)
                          #     @stock = @parent.stock_products.where("sellers_market_places_product_id IN (?)", @parent.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                          #     @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - order[:orderQty].to_i) >= 0 ? (@stock.count_on_hand - order[:orderQty].to_i) : 0 ) if @stock && @parent.quantity_inflations.present?
                          #   end
                          # else
                          #   type = (STOCKCONFIG[@variant.product.stock_config_type] == "default" ? STOCKCONFIG[@variant.product.seller.stock_config_type] : STOCKCONFIG[@variant.product.stock_config_type])
                          #   @variant.update_attributes(:fba_quantity=>(@variant.fba_quantity - order[:orderQty].to_i)) if !@variant.quantity_inflations.present?
                          #   if (type != "flat_quantity") || (type == "flat_quantity" && !@variant.product.kit.present?)
                          #     @stock = @variant.stock_products.where("sellers_market_places_product_id IN (?)", @variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                          #     @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - order[:orderQty].to_i) >= 0 ? (@stock.count_on_hand - order[:orderQty].to_i) : 0 ) if @stock
                          #   end
                          # end

                        end # end of option codes loop
                      end
                    end
                  else # is CM user else
                    Spree::MpOrderLineItem.create!(:order_id=>@order.id, :market_place_details=>@order.market_place_details)
                  end
                  @order.update_column(:total, order[:total])
                  @order.reload
                  ActiveSupport::Notifications.instrument('spree.order.contents_changed', {:user => nil, :order => @order})
                  @cart_numbers << order[:packNo]
                else # else for the order check condition
                  if @order.market_place_order_status != qoo10_statuses[k]
                    @order.update_attributes(:market_place_order_status=>qoo10_statuses[k])
                  end
                end
                @message << (@order && @order.present? ? (@order.market_place_order_no.to_s+": "+ "Success") : nil)
              rescue Exception => e
                @message << e.message
              end
            end # End of for loop
          end
        rescue Exception => e
          @message << e.message
        end
      else
        res_body = Hash.from_xml(res.body).to_json
        res_body = JSON.parse(res_body, :symbolize_names=>true)
        @message << res_body[:ShippingAPIService][:ResultMsg]
      end
    end
    @cart_numbers = @cart_numbers.uniq
    @message << "FBA: "+ Spree::Order.push_to_fba(@cart_numbers) if @cart_numbers.present?
    return @message.join("; ")
  end

  # Method to apply promotion if present
  def apply_promotion(order)
    items = order.line_items.count
    ActiveSupport::Notifications.instrument('spree.order.contents_changed', {:user => nil, :order => order})
    order.reload
    if order.line_items.count == items
      return
    else
      apply_promotion(order)
    end
  end

  # cancel order fetch from qoo10
  def cancel_order_fetch_qoo10(smp)
      @message = []
      market_place = Spree::MarketPlace.find(smp.market_place_id)
      #qoo10_claim_statuses = {"1"=>"Cancel Request", "2"=>"Cancelling", "3"=>"Cancel Completed", "4"=>"Return Request", "5"=>"Returning", "6"=>"Return completed"}
      #qoo10_claim_statuses.keys.each do |k|
         uri = URI(market_place.domain_url+'/ShippingBasicService.api/GetClaimInfo')
         req = Net::HTTP::Post.new(uri.path)
         req.set_form_data({'key'=> smp.api_secret_key, 'ClaimStat'=> '3', 'search_Sdate'=> '', 'search_Edate'=>''})
         res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end
         if res.code == "200"
            res_body = Hash.from_xml(res.body).to_json
            res_body = JSON.parse(res_body, :symbolize_names=> true)
            begin
             if res_body[:ShippingAPIService][:ResultMsg] == "Success"
               for i in 1..res_body[:ShippingAPIService][:TotalOrder].to_i
                 order = res_body[:ShippingAPIService][("Order"+i.to_s).to_sym]
                 # find out the order
                 @order = nil
                 @order = Spree::Order.where("market_place_order_no=? AND seller_id=?", order[:orderNo], smp.seller_id).try(:first)
                 # check order present or not and order should not be cancelled already
                  if @order.present? && !@order.is_cancel?
                      # code to cancel the order
                      if @order.update_attributes(:is_cancel=> true)
                        cm_user = !@order.is_bypass rescue true
                        if cm_user
                           seller_id = @order.seller_id
                           market_place_id = @order.market_place_id.present? ? @order.market_place_id : nil
                           product_id = @order.products.present? ? @order.products.first.id : nil
                           seller_market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", seller_id, market_place_id, product_id)
                           if seller_market_place_product.present?
                              # code to add the stock after cancelling the order
                              # if @order.line_items.present?
                              #   @order.line_items.each do |line_item|
                              #     stock = seller_market_place_product.first.product.stock_products.where("variant_id=? AND sellers_market_places_product_id=?", line_item.variant.id, seller_market_place_product.first.id).first
                              #     stock.variant.update_attributes(:fba_quantity=>stock.variant.fba_quantity + line_item.quantity) if stock && !stock.variant.quantity_inflations.present?
                              #     stock.update_attributes(:count_on_hand=>stock.count_on_hand + line_item.quantity) if stock
                              #   end
                              # end
                              @order.update_attributes!(:market_place_order_status => "cancel", :order_canceled_date=>order[:cancelRefundDate])
                              # call api in FBA to cancel the order
                              #@order.cancel_order_on_fba(smp)
                              @message << @order.market_place_order_no.to_s+": "+ "Success"
                           end # End if seller_product
                        else
                          @order.update_attributes!(:market_place_order_status => "cancel", :order_canceled_date=>order[:cancelRefundDate])
                          @order.mp_order_line_items.update_all(:is_cancel=>true)
                        end
                      else
                         @order.update_attributes(:is_cancel=> false, :order_canceled_date=>nil)
                         @message << @order.market_place_order_no.to_s+": "+ "Failure"
                      end # End if update order
                  else
                    @message << "Order not found!"
                  end # End if order nil
               end # End of for loop
             end # End of if
             # Order cancelation on FBA
             order_cancelation_on_fba(smp)
           rescue Exception => e
             @message << e.message
           end
         else
           res_body = Hash.from_xml(res.body).to_json
           res_body = JSON.parse(res_body, :symbolize_names=> true)
           @message << res_body[:ShippingAPIService][:ResultMsg]
         end
      #end # End of do
      return @message.join("; ")
  end

  def order_cancelation_on_fba(smp)
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
     # To get the array of uniq cart numbers on those orders which are already cancel on QSM and not cancelled on FBA.
     seller = smp.seller
     failed_orders = {}
     message = ""
     all_cart_numbers = seller.orders.where("market_place_id=? AND is_cancel=? AND (fulflmnt_state!=? OR fulflmnt_state IS NULL)", smp.market_place_id, true, 'cancel').map(&:cart_no).uniq
     all_cart_numbers.each do |cart_number|
       orders = []
       orders = Spree::Order.includes([:line_items, :mp_order_line_items]).where("cart_no=? AND ((spree_line_items.id IS NOT NULL) OR spree_mp_order_line_items.id IS NOT NULL)", cart_number)
       cancel_orders = orders.where("market_place_order_status IN (?) AND (fulflmnt_state!=? OR fulflmnt_state IS NULL)",['cancel','canceled'], 'cancel')
       if orders.present?
         total_orders = orders.count
         total_cancelled_orders = cancel_orders.count
         order = orders.first
         # All orders in one cart are cancelled
         if total_orders == total_cancelled_orders
           message = order.cancel_order_on_fba(smp, orders)
           failed_orders = failed_orders.merge(order.id=>[orders.map(&:market_place_order_no),message]) if message != true
         else
           if cancel_orders.present?
             cancel_orders.each do |cancel_order|
               if !cancel_order.is_bypass
                 cancel_order.line_items.each do |line_item|
                   variant = line_item.variant
                   res = cancel_order.cancel_order_item_on_fba(smp, variant)
                   my_logger.info('-----  cancel order on fba cm user')
                   my_logger.info(res)
                   Spree::Variant.fetch_qty_from_fba(smp,variant)
                   message += (res == true ? "" : (variant.sku+": "+res+", "))
                 end
               else
                 cancel_order.mp_order_line_items.each do |line_item|
                   sku = line_item.sku
                   res = cancel_order.cancel_order_item_on_fba(smp, sku)
                   my_logger.info('-----  cancel order on fba not cm user')
                   my_logger.info(res)
                   message += (res == true ? "" : (sku+": "+res+", "))
                 end
               end
               failed_orders = failed_orders.merge(order.id=>[[cancel_order.market_place_order_no],message]) if message.present?
             end
           end
         end
       end
     end # end all cart do loop
     #Spree::OrderMailer.order_not_cancelled_notification(failed_orders).deliver if failed_orders.present?
  end

  # Listing of products variants through excel on lazada
  def listing_products_lazada(product, sellers_market_places_product, option_name, option_value, variant_price, variant_selling_price, quantity, variant_sku)
      @error_message = ""
      begin
        @sellers_market_places_product = sellers_market_places_product
        @market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @sellers_market_places_product.seller_id, @sellers_market_places_product.market_place_id, product.id)
        @taxon_market_plcaes = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", product.taxons.first.id, @sellers_market_places_product.market_place_id) if product.taxons.present?
        if @taxon_market_plcaes && !@taxon_market_plcaes.blank?
        market_place = Spree::MarketPlace.find(@sellers_market_places_product.market_place_id)
            user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", @sellers_market_places_product.seller_id, @sellers_market_places_product.market_place_id)
            user_market_place = user_market_place.first
            variant = Spree::Variant.find_by_sku(variant_sku) if variant_sku.present?
            if !user_market_place.nil? && !user_market_place.api_secret_key.nil?
              Time.zone = "Singapore"
              current_time = Time.zone.now
              user_id = user_market_place.contact_email
              http = Net::HTTP.new(market_place.domain_url)
              product_params = {"Action"=>"ProductCreate", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
              signature = generate_lazada_signature(product_params, user_market_place)
              if signature
                formed_params = []
                sorted_params = Hash[product_params.sort]
                sorted_params.merge!("Signature"=>signature)
                sorted_params.each do |key,value|formed_params << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
                param_string = "?"+formed_params.join('&')
                uri = URI.parse(market_place.domain_url+param_string)
                http = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = true
                http.verify_mode = OpenSSL::SSL::VERIFY_NONE
                request = Net::HTTP::Post.new(uri.request_uri)
                #Product params details
                brand = product.brand ? product.brand.name : "3M"
                description = product.description
                name = product.name
                price = variant_price ? variant_price.to_f : product.price.to_f
                primary_category = @taxon_market_plcaes.first.market_place_category_id
                category = ''
                seller_sku = variant_sku ? variant_sku : product.sku
                parent_sku = variant_sku ? variant_sku : product.sku
                tax_class = 'default'
                #sale_price = variant_selling_price ? variant_selling_price.to_f : product.selling_price.to_f
                sale_price = variant_selling_price
                sale_start_date = product.available_on ? product.available_on : Time.now()
                sale_end_date = ''
                shipment_type = 'dropshipping'
                product_id = ''
                conditon = 'new'
                product_data = ''
                variation = option_value ? option_value : ''
                quantity = quantity.nil? ? 0 : quantity
                short_desc = product.meta_description
                package_content = product.package_content
                if variant.present?
                  height = variant.height.to_f
                  weight = variant.weight.to_f
                  length = variant.depth.to_f
                  width = variant.width.to_f
                else
                  height = 0.0
                  weight = 0.0
                  length = 0.0
                  width = 0.0
                end
                xml_obj = {:Product=>{:Brand=>brand, :Description=>description, :Name=>name, :Price=>price, :PrimaryCategory=>primary_category, :Categories=>category, :SellerSku=>seller_sku, :ParentSku=>parent_sku, :TaxClass=>tax_class, :Variation=>variation, :SalePrice=>sale_price, :SaleStartDate=>sale_start_date, :SaleEndDate=>sale_end_date, :ShipmentType=>shipment_type, :ProductId=>product_id, :Condition=>conditon, :ProductData=>product_data, :Quantity=>quantity,:ProductData=>{:ShortDescription=>short_desc, :PackageContent=>package_content, :PackageHeight=>height, :PackageLength=>length, :PackageWidth=>width, :PackageWeight=>weight}}}
                request.body = xml_obj.to_xml.gsub("hash", "Request")
                res = http.request(request)
                res_body = Hash.from_xml(res.body).to_json
                res_body = JSON.parse(res_body, :symbolize_names=>true)
                if res.code == "200" && res_body[:SuccessResponse]
                  mp_product_code = res_body[:SuccessResponse][:Head][:RequestId]
                  @market_place_product.first.update_attributes(:market_place_product_code=>mp_product_code) if !@market_place_product.blank?
                  #image upload code
                  @images = @variant ? @variant.images : product.images
                  if !@images.blank?
                    image_arr = []
                    @images.each do |image|
                      image_arr << image.attachment.url(:original).to_s if image.attachment_file_name.split("_").first.capitalize == market_place.code.capitalize
                    end
                    if image_arr.present?
                      image_params = {"Action"=>"Image", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
                      img_signature = generate_lazada_signature(image_params, user_market_place)
                      img_formed_params = []
                      img_sorted_params = Hash[image_params.sort]
                      img_sorted_params.merge!("Signature"=>img_signature)
                      img_sorted_params.each do |key,value|img_formed_params << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
                      img_param_string = "?"+img_formed_params.join('&')
                      img_uri = URI.parse(market_place.domain_url+img_param_string)
                      img_http = Net::HTTP.new(img_uri.host, img_uri.port)
                      img_http.use_ssl = true
                      img_http.verify_mode = OpenSSL::SSL::VERIFY_NONE
                      img_request = Net::HTTP::Post.new(img_uri.request_uri)
                      img_sku = product.sku
                      img_xml_obj = {:ProductImage=>{:SellerSku=>img_sku, :Images=>image_arr}}
                      img_request.body = img_xml_obj.to_xml(:skip_types=>true).gsub("hash", "Request")
                      img_res = http.request(img_request)
                      img_res_body = Hash.from_xml(img_res.body).to_json
                      img_res_body = JSON.parse(img_res_body, :symbolize_names=>true)
                      if img_res.code == "200" && img_res_body[:ErrorResponse]
                        @error_message << user_market_place.market_place.name+": "+img_res_body[:ErrorResponse][:Head][:ErrorMessage]
                      end
                    else
                      @error_message << user_market_place.market_place.name+": "+"Image not found"
                    end
                  end
                else
                  @error_message << user_market_place.market_place.name+": "+res_body[:ErrorResponse][:Head][:ErrorMessage]
                end
              else
                @error_message << "#{market_place.name}: Signature can not be generated."
              end
          end
        else
          @error_message << "Please map market place category to list product."
        end
       rescue Exception => e
         @error_message << e.message
       end
      return @error_message && @error_message.length > 0 ? @error_message : true
    end

  # to get count for corresponding order list
  def get_order_count(list)
      @counts = []
       case list
       when "complete"
          @counts << Spree::Order.includes(:line_items).where("spree_line_items.id IS NOT NULL AND fulflmnt_state IN ('complete', 'customer_complete', 'self_collect_complete', 'collect_complete', 'return_complete')").count
          @counts << Spree::Order.includes(:line_items).where("spree_line_items.id IS NOT NULL AND is_pick_at_store = true AND fulflmnt_state IN ('complete', 'customer_complete', 'self_collect_complete', 'collect_complete', 'return_complete')").count
          @counts << Spree::Order.includes(:line_items).where("spree_line_items.id IS NOT NULL AND is_pick_at_store = false AND fulflmnt_state IN ('complete', 'customer_complete', 'self_collect_complete', 'collect_complete', 'return_complete')").count
       when "partial"
         return Spree::Order.includes(:line_items).where("fulflmnt_tracking_no IS NULL AND is_cancel=false").count
       when "cancel"
          @counts << Spree::Order.includes(:line_items).where("spree_line_items.id IS NOT NULL AND fulflmnt_state='cancel'").count
          @counts << Spree::Order.includes(:line_items).where("spree_line_items.id IS NOT NULL AND is_pick_at_store = true AND fulflmnt_state='cancel'").count
          @counts << Spree::Order.includes(:line_items).where("spree_line_items.id IS NOT NULL AND is_pick_at_store = false AND fulflmnt_state='cancel'").count
       when "tracker"
          @counts << Spree::Order.includes(:line_items).where("spree_line_items.id IS NOT NULL").count
          @counts << Spree::Order.includes(:line_items).where("spree_line_items.id IS NOT NULL AND is_pick_at_store = true").count
          @counts << Spree::Order.includes(:line_items).where("spree_line_items.id IS NOT NULL AND is_pick_at_store = false").count
       when 'partial_cancel'
         return Spree::Order.includes(:line_items).where("cancel_on_fba=false AND is_cancel=true").count
       end
       return @counts
    end

  # to sync all orders in SF from Qoo10, clubbed/merged it according to cart and then push to FBA
  def sync_all_orders_qoo10(orders)
     @message = []
     @cart_numbers = []
      begin
      orders.each do |ord|
        if !ord.products.present?
          @order = nil
          @shpping_address = nil
          @billing_address = nil
          @is_customer_pickup = nil
          order = ord.market_place_details
          @order = Spree::Order.find_by_market_place_order_no(order["orderNo"]) if order.present?
            if @order.present? && order.present?
              gift = order["Gift"].present? ? false : true
              shipping_country = Spree::Country.find_by_iso(order["shippingCountry"])
              billing_country = Spree::Country.find_by_iso(order["senderNation"])
              name = order["receiver"].present? ? order["receiver"] : (order["buyer"].present? ? order["buyer"] : "NA")
              telno = order["receiverTel"].present? ? order["receiverTel"] : (order["buyerTel"].present? ? order["buyerTel"] : "NA")
              mobileno = order["receiverMobile"].present? ? order["receiverMobile"] : (order["buyerMobile"].present? ? order["buyerMobile"] : "NA")
              if order["OrderType"] == "Pickup"
                @is_customer_pickup = true
                # our singapore warehouse address
                address1 = "151 Pasir Panjang Road"
                address2 = "#02-02 Pasir Panjang Distripark"
                zipcode = "118480"
                phone = "+65 6271 0524"
                @order.shipping_address.update_attributes(:firstname=> name, :lastname=> name, :address1=> address1, :address2=> address2,
                :city=> shipping_country.name, :zipcode=> zipcode, :phone=> phone, :alternative_phone=> "", :country_id=> shipping_country.id,
                :state_name=> shipping_country.name)
                if order[:Addr1].present?
                  @order.billing_address.update_attributes(:firstname=> name, :lastname=> name, :address1=> order["Addr1"], :address2=> order["Addr2"],
                  :city=> shipping_country.name, :zipcode=> order["zipCode"], :phone=> telno, :alternative_phone=> mobileno, :country_id=> shipping_country.id,
                  :state_name=> shipping_country.name)
                end
              else
                @is_customer_pickup = false
                @order.shipping_address.update_attributes(:firstname=> name, :lastname=> name,
                                                                                      :address1=> order["Addr1"], :address2=> order["Addr2"],
                                                                                      :city=> shipping_country.name, :zipcode=> order["zipCode"],
                                                                                      :phone=> telno, :alternative_phone=> mobileno,
                                                                                      :country_id=> shipping_country.id, :state_name=> shipping_country.name)
               end
               if !order["senderName"].present? && !order["senderAddr"].present? && !order["senderNation"].present? && !order["senderZipCode"].present? && !order["senderTel"].present? && !billing_country.nil?
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
               @order.update_attributes(:number=> order["orderNo"], :order_date=> order["PaymentDate"], :item_total=> order["orderPrice"],
                                                          :total=> order["total"], :payment_total=> order["total"],
                                                          :email=> order["buyerEmail"], :currency=> order["Currency"],
                                                          :send_as_gift=> gift, :market_place_id=> @mp_product.present? ? @mp_product.market_place_id : nil,
                                                          :market_place_order_no=> order["orderNo"],
                                                          :bill_address_id=> billing_address, :ship_address_id=> @order.shipping_address.id)
               #@order.adjustments.first.update_attributes(:amount=> -order["discount"].to_f, :label=> "discount") if @order && @order.adjustments.present? && order["discount"].to_f != 0.0
               if @mp_product.present? && @order.present?
                 if order["option"] == ""
                   # options not present i.e. for product
                   @variant = Spree::Variant.find_by_sku(@mp_product.product.sku)
                   if !@mp_product.nil? && !@mp_product.blank? && !@variant.nil? && !@variant.blank?
                     @line_item = Spree::LineItem.create!(:variant_id=> @variant.id, :order_id=> @order.id, :quantity=> order["orderQty"].to_i, :price=> order["orderPrice"], :currency=> order["Currency"], :is_pick_at_store => @is_customer_pickup)
                     @stock = @mp_product.product.stock_products.first
                   end
                 else
                   # options are present i.e. for variant
                   #option_arr = order["option"].split("(")[0].split(":")
                   option_arr = order[:option].split(":")
                   if option_arr[1].split("(+").count > 1
                     option_arr[1] = option_arr[1].split("(+")[0]
                   elsif option_arr[1].split("(-").count > 1
                     option_arr[1] = option_arr[1].split("(-")[0]
                   end
                   @variant = nil
                   @mp_product.product.variants.each do |v|
                     @variant = v if !v.option_values.blank? && (v.option_values.map(&:presentation).include?option_arr[1].strip)
                   end if !@mp_product.nil? && @mp_product.product && @mp_product.product.option_types && !@mp_product.product.option_types.blank? && (@mp_product.product.option_types.map(&:presentation).include?option_arr[0])
                   if !@mp_product.nil? && !@mp_product.blank? && !@variant.nil? && !@variant.blank?
                     @line_item = Spree::LineItem.create!(:variant_id=> @variant.id, :order_id=> @order.id, :quantity=> order["orderQty"].to_i, :price=> order["orderPrice"], :currency=> order["Currency"], :is_pick_at_store => @is_customer_pickup)
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
                 # reload the order object
                 @order.reload
                 # add cart number into array
                 @cart_numbers << order["packNo"]
               end
             end
             @message << (@order && @order.present? ? (@order.market_place_order_no.to_s+": "+ "Success") : nil)
           end # end of if product does not exist
         end # end of orders loop
       rescue Exception => e
         @message << e.message
       end
       # take only unique cart number from array
       @cart_numbers = @cart_numbers.uniq
       # pass the array to method which can clubbed the orders according to cart number and then push to FBA
       @message << "FBA: "+ Spree::Order.push_to_fba(@cart_numbers)
       return @message.join("; ")
  end

  # Fetch cancel orders from Lazada
  def cancel_order_fetch_lazada(smp)
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    any_order_cancel = false
    @messages = []
    seller = smp.seller
    @orders = seller.orders.where("market_place_id=? AND market_place_order_status IN(?)", smp.market_place_id, ['pending', 'ready to ship'])
    if @orders.present?
      my_logger.info('@orders  present')
      @orders.each do |order|
        cm_user = !order.is_bypass rescue true
        my_logger.info(order)
        begin
          # List item fetch from order API
            Time.zone = "Singapore"
            current_time = Time.zone.now
            list_item_params = {"Action"=>"GetOrderItems", "OrderId"=>order.market_place_order_no, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>smp.contact_email, "Version"=>"1.0"}
            signature = ApiJob.generate_lazada_signature(list_item_params, smp)
            market_place = smp.market_place
            if signature.present?
              string_to_be_formed = []
              sorted_params = Hash[list_item_params.sort]
              sorted_params.merge!("Signature"=>signature)
              sorted_params.each do |key,value|string_to_be_formed << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
              param_string = "?"+string_to_be_formed.join('&')
              uri = URI.parse(market_place.domain_url+param_string)
              http = Net::HTTP.new(uri.host, uri.port)
              http.use_ssl = true
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
              request = Net::HTTP::Get.new(uri.request_uri)
              res = http.request(request)
              if res.code == "200"
                res_body = Hash.from_xml(res.body).to_json
                res_body = JSON.parse(res_body, :symbolize_names=>true)
                # res_body = {:SuccessResponse=>{:Head=>{:RequestId=>nil, :RequestAction=>"GetOrderItems", :ResponseType=>"OrderItems", :Timestamp=>"2016-01-06T21:40:03+0800"}, :Body=>{:OrderItems=> {:OrderItem=>[{:OrderItemId=>"91417", :ShopId=>"4957053", :OrderId=>"127250", :Name=>"Kit ACDrives and BrassHinges", :Sku=>"FPCPROD001", :ShopSku=>"MA619BE10NBDSG-1051143", :ShippingType=>"Dropshipping", :ItemPrice=>"499.00", :PaidPrice=>"499.00", :Currency=>"SGD", :WalletCredits=>"0.00", :TaxAmount=>"32.64", :ShippingAmount=>"0.00", :ShippingServiceCost=>nil, :VoucherAmount=>"0", :VoucherCode=>nil, :Status=>"canceled", :ShipmentProvider=>"Ninja Van Marketplace", :TrackingCode=>"ZNVMKP-2808-205373278-7945", :Reason=>nil, :ReasonDetail=>nil, :PurchaseOrderId=>"100176", :PurchaseOrderNumber=>"MPDS-M15512763796", :PackageId=>"MPDS-205373278-7945", :PromisedShippingTime=>nil, :CreatedAt=>"2015-12-08 15:20:03", :UpdatedAt=>"2015-12-14 17:20:13"},{:OrderItemId=>"91417", :ShopId=>"4957053", :OrderId=>"127250", :Name=>"Kit ACDrives and BrassHinges", :Sku=>"NAILBLUE001_16011318347", :ShopSku=>"MA619BE10NBDSG-1051143", :ShippingType=>"Dropshipping", :ItemPrice=>"499.00", :PaidPrice=>"499.00", :Currency=>"SGD", :WalletCredits=>"0.00", :TaxAmount=>"32.64", :ShippingAmount=>"0.00", :ShippingServiceCost=>nil, :VoucherAmount=>"0", :VoucherCode=>nil, :Status=>"canceled", :ShipmentProvider=>"Ninja Van Marketplace", :TrackingCode=>"ZNVMKP-2808-205373278-7945", :Reason=>nil, :ReasonDetail=>nil, :PurchaseOrderId=>"100176", :PurchaseOrderNumber=>"MPDS-M15512763796", :PackageId=>"MPDS-205373278-7945", :PromisedShippingTime=>nil, :CreatedAt=>"2015-12-08 15:20:03", :UpdatedAt=>"2015-12-14 17:20:13"},{:OrderItemId=>"91417", :ShopId=>"4957053", :OrderId=>"127250", :Name=>"Kit ACDrives and BrassHinges", :Sku=>"NEWRKIT", :ShopSku=>"MA619BE10NBDSG-1051143", :ShippingType=>"Dropshipping", :ItemPrice=>"499.00", :PaidPrice=>"499.00", :Currency=>"SGD", :WalletCredits=>"0.00", :TaxAmount=>"32.64", :ShippingAmount=>"0.00", :ShippingServiceCost=>nil, :VoucherAmount=>"0", :VoucherCode=>nil, :Status=>"canceled", :ShipmentProvider=>"Ninja Van Marketplace", :TrackingCode=>"ZNVMKP-2808-205373278-7945", :Reason=>nil, :ReasonDetail=>nil, :PurchaseOrderId=>"100176", :PurchaseOrderNumber=>"MPDS-M15512763796", :PackageId=>"MPDS-205373278-7945", :PromisedShippingTime=>nil, :CreatedAt=>"2015-12-08 15:20:03", :UpdatedAt=>"2015-12-14 17:20:13"}]}}}}
                my_logger.info(res_body)
                order_items = res_body[:SuccessResponse][:Body][:OrderItems][:OrderItem] if res_body[:SuccessResponse].present?

                if order_items.present? && order_items.class == Array
                  my_logger.info('order_items  present and array')
                  order_items.each do |ord_item|
                    if ord_item[:Status] == "canceled"
                      my_logger.info('canceled')
                      any_order_cancel = true
                      if cm_user
                        my_logger.info('cm user')
                        variants = []
                        kit = Spree::Kit.where("sku=?", ord_item[:Sku])
                        if kit.present?
                          my_logger.info('kit')
                          kps = kit.first.kit_products
                          variants_id = kps.map(&:variant_id)
                          variants = Spree::Variant.where("id IN (?)", variants_id)
                        else
                          my_logger.info('not kit')
                          old_variants = Spree::Variant.where("sku=?", ord_item[:Sku])
                          old_variants.each do |v|
                            if v.parent_id.present?
                              kit = Spree::Kit.where("sku=?", v.sku)
                              if kit.present?
                                kps = kit.first.kit_products
                                variants_id = kps.map(&:variant_id)
                                variants = Spree::Variant.where("id IN (?)", variants_id)
                              else
                                 variants = Spree::Variant.where("id IN (?)", v.parent_id)
                              end
                            else
                              variants = Spree::Variant.where("sku=?", v.sku)
                            end
                          end
                        end
                        my_logger.info('now variants')
                        variants.each do |variant|
                          variant = Spree::Variant.find_by_sku(ord_item[:Sku])
                          line_item = variant.parent_id.present? ? order.line_items.find_by_variant_id(variant.parent_id) : order.line_items.find_by_variant_id(variant.id)
                          if line_item.present?
                            my_logger.info('line item  present')
                            seller_market_place_product = line_item.variant.product.sellers_market_places_products rescue nil
                            if seller_market_place_product.present?
                              my_logger.info('seller market place product  present')
                              # code to add the stock after cancelling the order
                              stock = seller_market_place_product.first.product.stock_products.where("variant_id=? AND sellers_market_places_product_id=?", line_item.variant.id, seller_market_place_product.first.id).first rescue nil
                                # variant.update_attributes(:fba_quantity=>variant.fba_quantity + line_item.quantity) if stock && !variant.quantity_inflations.present?
                              # stock.update_attributes(:count_on_hand=>stock.count_on_hand + line_item.quantity) if stock
                              if order.line_items.count > 1 && stock.present?
                                my_logger.info('create dup')
                                cancel_order = order.dup
                                can_ord_number_count = Spree::Order.where("cart_no=? AND is_cancel=?", order.cart_no, true).count + 1
                                cancel_order.market_place_order_no = order.cart_no.to_s+"-"+ord_item[:Sku].to_s+"-C"+can_ord_number_count.to_s
                                cancel_order.is_cancel = true
                                cancel_order.market_place_order_status = "cancel"
                                cancel_order.fulflmnt_tracking_no = nil
                                cancel_order.order_canceled_date = Time.zone.now()
                                cancel_order.save
                                line_item.update_column(:order_id,cancel_order.id)
                              elsif stock.present?
                                my_logger.info('not create dup stock')
                                order.update_attributes(:is_cancel=> true, :order_canceled_date=>Time.zone.now())
                                order.update_attributes!(:market_place_order_status => "cancel")
                              end
                              # call api in FBA to cancel the order
                              #message = order.cancel_order_item_on_fba(smp, line_item.variant)
                              #@messsges << (order.number.to_s+": "+ message) if message.length > 0
                            end # End if seller_product
                          end
                        end # End of variants loop
                      else # CM user else
                        mp_line_items = order.mp_order_line_items
                      if mp_line_items.count > 1
                        mp_line_items.each do |mlt|
                          if mlt.market_place_details["Sku"] == ord_item[:Sku]
                            cancel_order = order.dup
                            can_ord_number_count = Spree::Order.where("cart_no=? AND is_cancel=?", order.cart_no, true).count + 1
                            cancel_order.market_place_order_no = order.cart_no.to_s+"-"+ord_item[:Sku].to_s+"-C"+can_ord_number_count.to_s
                            cancel_order.is_cancel = true
                            cancel_order.market_place_order_status = "cancel"
                            cancel_order.fulflmnt_tracking_no = nil
                            cancel_order.order_canceled_date = Time.zone.now()
                            cancel_order.save
                            mlt.update_column(:is_cancel, true)
                          end
                        end
                      else
                        order.update_attributes!(:is_cancel=> true, :order_canceled_date=>Time.zone.now(), :market_place_order_status => "cancel")
                        order.mp_order_line_items.update_all(:is_cancel=>true)
                      end
                      end
                      order.update_column(:total=>(order.total.to_f - ord_item[:PaidPrice].to_f))
                    end
                  end # End of order_items loop
                elsif order_items.present? && order_items.class != Array && order_items[:Status] == "canceled"
                  my_logger.info('not array')
                  any_order_cancel = true
                  ord_item = order_items
                  if cm_user
                    variants = []
                    kit = Spree::Kit.where("sku=?", ord_item[:Sku])
                    if kit.present?
                      kps = kit.first.kit_products
                      variants_id = kps.map(&:variant_id)
                      variants = Spree::Variant.where("id IN (?)", variants_id)
                    else
                      my_logger.info('not kit')
                      old_variants = Spree::Variant.where("sku=?", ord_item[:Sku])
                      old_variants.each do |v|
                        if v.parent_id.present?
                          kit = Spree::Kit.where("sku=?", v.sku)
                          if kit.present?
                            kps = kit.first.kit_products
                            variants_id = kps.map(&:variant_id)
                            variants = Spree::Variant.where("id IN (?)", variants_id)
                          else
                            variants = Spree::Variant.where("id IN (?)", v.parent_id)
                          end
                        else
                          variants = Spree::Variant.where("sku=?", v.sku)
                        end
                      end
                    end
                    variants.each do |variant|
                      variant = Spree::Variant.find_by_sku(ord_item[:Sku])
                      line_item = order.line_items.find_by_variant_id(variant.id) if variant
                      if line_item.present?
                        seller_market_place_product = line_item.variant.product.sellers_market_places_products rescue nil
                        if seller_market_place_product.present?
                          # code to add the stock after cancelling the order
                          stock = seller_market_place_product.first.product.stock_products.where("variant_id=? AND sellers_market_places_product_id=?", line_item.variant.id, seller_market_place_product.first.id).first rescue nil
                          # variant.update_attributes(:fba_quantity=>variant.fba_quantity + line_item.quantity) if stock && !variant.quantity_inflations.present? && !variant.parent_id.present?
                          # stock.update_attributes(:count_on_hand=> stock.count_on_hand + line_item.quantity) if stock
                          if order.line_items.count > 1 && stock.present?
                            cancel_order = order.dup
                            can_ord_number_count = Spree::Order.where("cart_no=? AND is_cancel=?", order.cart_no, true).count + 1
                            cancel_order.market_place_order_no = order.cart_no.to_s+"-"+ord_item[:Sku].to_s+"-C"+can_ord_number_count.to_s
                            cancel_order.is_cancel = true
                            cancel_order.market_place_order_status = "cancel"
                            cancel_order.order_canceled_date = Time.zone.now()
                            cancel_order.save
                            line_item.update_column(:order_id,cancel_order.id)
                          elsif stock.present?
                            order.update_attributes!(:is_cancel=> true, :order_canceled_date=>Time.zone.now(), :market_place_order_status => "cancel")
                          end
                          # call api in FBA to cancel the order
                          #message = order.cancel_order_item_on_fba(smp, line_item.variant)
                          #@messsges << (order.to_s+": "+ message) if message.length > 0
                        end # End if seller_product
                      end
                    end # End of variants loop
                  else # CM user else
                    my_logger.info('not cm')
                    mp_line_items = order.mp_order_line_items
                    if mp_line_items.count > 1
                      mp_line_items.each do |mlt|
                        if mlt.market_place_details["Sku"] == ord_item[:Sku]
                          cancel_order = order.dup
                          can_ord_number_count = Spree::Order.where("cart_no=? AND is_cancel=?", order.cart_no, true).count + 1
                          cancel_order.market_place_order_no = order.cart_no.to_s+"-"+ord_item[:Sku].to_s+"-C"+can_ord_number_count.to_s
                          cancel_order.is_cancel = true
                          cancel_order.market_place_order_status = "cancel"
                          cancel_order.order_canceled_date = Time.zone.now()
                          cancel_order.save
                          mlt.update_column(:is_cancel, true)
                        end
                      end
                    else
                      order.update_attributes!(:is_cancel=> true, :order_canceled_date=>Time.zone.now(), :market_place_order_status => "cancel")
                      order.mp_order_line_items.update_all(:is_cancel=>true)
                    end
                  end
                  order.update_column(:total,(order.total.to_f - order_items[:PaidPrice].to_f))
                  my_logger.info('update cancel date')
                end # End of array class check condition
              end
              # Order cancelation on FBA
            else
              @messsges << "#{market_place.name}: Signature can not be generated."
            end
        rescue Exception => e
          #@messsges << e.message
        end
      end # end of loop
    end # end of if condition
    order_cancelation_on_fba(smp) #if any_order_cancel
    return @messages.join("; ")
  end

  # Custom excel file generation
  def generate_excel(collections, heading, options={})
    message = ""
    xls_file = Spreadsheet::Workbook.new
    sheet = xls_file.create_worksheet :name => "Sheet 1"
    red = Spreadsheet::Format.new :color => 'black', :size => 10, :align => 'center', :pattern_fg_color => :red, :pattern => 1
    begin
      collections.each_with_index do |err, index|
        err.each do |r|
          #next unless r.present?
          sheet.row(index).push r
        end
      end
    rescue Exception => e
      message = e.message
    end
    blob = StringIO.new("")
    #blob = message if !message.present?
    xls_file.write blob
    blob.string
  end

  # Custom excel file generation multiple worksheets
  def generate_excel_multi_worksheet(collections, options={})
    message = ""
    xls_file = Spreadsheet::Workbook.new
    begin
      collections.each do |key, values|
        sheet = xls_file.create_worksheet :name => key
        red = Spreadsheet::Format.new :color => 'black', :size => 10, :align => 'center', :pattern_fg_color => :red, :pattern => 1
        values.each_with_index do |err, index|
          err.each do |r|
            #next unless r.present?
            sheet.row(index).push r
          end
        end
      end
    rescue Exception => e
      message = e.message
    end
    blob = StringIO.new("")
    #blob = message if !message.present?
    xls_file.write blob
    blob.string
  end

  # Fetch delivered order from Qoo10, change status to SF and FBA
  def fetch_qoo10_delivered_orders(smp)
    @message = []
    @all_cart_numbers = []
    fba_complete_states = ['complete', 'customer_complete', 'self_collect_complete', 'collect_complete', 'return_complete']
    market_place = smp.market_place
    #qoo10_statuses = {"5"=>"Delivered", "4"=>"On delivery"}
    qoo10_statuses = {"5"=>"Delivered"}
    for j in 1..10
      begin
        s_date = j.day.ago.strftime("%Y%m%d")
        e_date = (j-1).day.ago.strftime("%Y%m%d")
        qoo10_statuses.keys.each do |k|
          uri = URI(market_place.domain_url+'/ShippingBasicService.api/GetShippingInfo')
          req = Net::HTTP::Post.new(uri.path)
          req.set_form_data({'key'=>smp.api_secret_key,'ShippingStat'=>k,'search_Sdate'=>s_date,'search_Edate'=>e_date})
          res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end
          if res.code == "200"
            res_body = Hash.from_xml(res.body).to_json
            res_body = JSON.parse(res_body, :symbolize_names=>true)
            begin
              if res_body[:ShippingAPIService][:ResultMsg] == "Success"
                for i in 1..res_body[:ShippingAPIService][:TotalOrder].to_i
                  order = res_body[:ShippingAPIService][("Order"+i.to_s).to_sym]
                  # find out the order
                  @order = nil
                  @order = Spree::Order.where("market_place_order_no=? AND seller_id=?", order[:orderNo], smp.seller_id).try(:first)
                  # check order present or not and order should not be cancelled already
                  if @order.present? && !@order.is_cancel?
                    # code to delivered the order
                    if @order.update_attributes!(:market_place_order_status => "Delivered")
                      @all_cart_numbers << @order.cart_no if @order.market_place_order_status == "Delivered" && (!fba_complete_states.include?@order.fulflmnt_state)
                    else
                      @message << "Order not found!"
                    end # End of success status change in SF if
                  end # End if order nil
                end # End of for loop
              end # End of success if
              @all_cart_numbers = @all_cart_numbers.uniq
              #Call to FBA to change status
              Spree::Order.update_fba_state(@all_cart_numbers.uniq, smp, "Completed") if @all_cart_numbers.present?
            rescue Exception => e
              @message << e.message
            end
          else
             res_body = Hash.from_xml(res.body).to_json
             res_body = JSON.parse(res_body, :symbolize_names=> true)
             @message << res_body[:ShippingAPIService][:ResultMsg]
          end
        end # End of status do
      rescue Exception => e
        @message << e.message
      end
    end # End for loop for day
    return @message.join("; ")
  end

  # Fetch order invoice for lazada orders and push to FBA
  def fetch_invoice_from_lazada(smp)
    @messages = []
    @orders = smp.seller.orders.where("invoice_details IS NULL AND market_place_id=? AND is_cancel=false AND fulflmnt_state not in(?)", smp.market_place_id, ['rfp','partial'])
    market_place = smp.market_place
    if @orders.present?
      @orders.each do |order|
        begin
          # List item fetch from order API
          order_item_code = []
          Time.zone = "Singapore"
          current_time = Time.zone.now
          list_item_params = {"Action"=>"GetOrderItems", "OrderId"=>order.market_place_order_no, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>smp.contact_email, "Version"=>"1.0"}
          signature_lt = generate_lazada_signature(list_item_params, smp)
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
            if res_lt.code == "200"
              res_lt_body = Hash.from_xml(res_lt.body).to_json
              res_lt_body = JSON.parse(res_lt_body, :symbolize_names=>true)
              if res_lt_body[:SuccessResponse]
                order_items = res_lt_body[:SuccessResponse][:Body][:OrderItems][:OrderItem]
                if order_items.class == Array
                  order_items.each do |order_item|
                    order_item_code = order_item[:OrderItemId]
                  end
                elsif order_items.class != Array
                  order_item_code = order_items[:OrderItemId]
                end
                #Invoice generation call
                order_item_code = (order_item_code.present? ? order_item_code : '')
                invoice_no = order.fulflmnt_tracking_no ? order.fulflmnt_tracking_no : "12345"
                invoice_params = {"Action"=>"GetDocument", "DocumentType"=>"invoice", "InvoiceNumber"=>invoice_no, "OrderItemId"=>order_item_code, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>smp.contact_email, "Version"=>"1.0"}
                signature = generate_lazada_signature(invoice_params, smp)
                if signature.present?
                  string_to_be_formed = []
                  sorted_params = Hash[invoice_params.sort]
                  sorted_params.merge!("Signature"=>signature)
                  sorted_params.each do |key,value|string_to_be_formed << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
                  param_string = "?"+string_to_be_formed.join('&')
                  uri = URI.parse(market_place.domain_url+param_string)
                  http = Net::HTTP.new(uri.host, uri.port)
                  http.use_ssl = true
                  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
                  request = Net::HTTP::Get.new(uri.request_uri)
                  res = http.request(request)
                  if res.code == "200"
                    res_body = Hash.from_xml(res.body).to_json
                    res_body = JSON.parse(res_body, :symbolize_names=>true)
                    if res_body[:SuccessResponse]
                      #FBA invoice push API call
                      fba_res = order.send_invoice(smp, order, res_body[:SuccessResponse][:Body][:Documents][:Document][:File])
                      order.update_column(:invoice_details,res_body[:SuccessResponse][:Body][:Documents][:Document][:File])  if fba_res
                    else
                      @messages << "#{market_place.name}: ["+"#{order.market_place_order_no.to_s}"+"]"+res_body[:ErrorResponse][:Head][:ErrorMessage]
                    end
                  end
                else
                  @messsges << "#{market_place.name}: Signature can not be generated."
                end # End for invoice signature check
              else
                @messages << "#{market_place.name}: ["+"#{order.market_place_order_no.to_s}"+"] "+res_lt_body[:ErrorResponse][:Head][:ErrorMessage]
              end # End for line items error check
            end
          else
            @messsges << "#{market_place.name}: Signature can not be generated."
          end # End for the line items signature check
        rescue Exception => e
          @messsges << "#{market_place.name}: ["+"#{order.market_place_order_no.to_s}"+"] "+e.message
        end
      end # End for order loop
    end # End for order present check
    return @messages.join("; ")
  end

 # Get total fba available stock
  def fba_stock_calculate(product)
    stock = 0
    if product.variants.present?
      stock = product.variants.sum(&:fba_quantity)
    else
      variant = Spree::Variant.where("sku=? AND product_id=?",product.sku, product.id)
      stock = variant.first.fba_quantity if variant.present?
    end
    return stock
  end

#  Get products on market place allocated stock
  def product_market_place_stock(product)
    mp_stock={}
    market_places = product.market_places.where("spree_market_places.id IN (?)", product.seller.seller_market_places.where(:is_active=>true).map(&:market_place_id))
    market_places.each do |mp|
      stock = 0
      variants = product.variants.present? ? product.variants : Spree::Variant.where("Product_id=?", product.id)
      if variants.present?
        variants.each do |variant|
          begin
            v_stock_products = Spree::StockProduct.includes(:sellers_market_places_product).where("spree_sellers_market_places_products.market_place_id=? AND spree_sellers_market_places_products.product_id=? AND spree_stock_products.variant_id=?", mp.id, variant.product.id, variant.id)
            stock = stock + v_stock_products.sum(&:count_on_hand)
          rescue
          end
        end
      end
      mp_stock = mp_stock.merge(mp.name=>stock)
      break if (STOCKCONFIG[product.stock_config_type] == "flat_quantity") || (STOCKCONFIG[product.stock_config_type] == "default" && STOCKCONFIG[product.seller.stock_config_type] == "flat_quantity")
    end if product.present? && market_places.present?
    return mp_stock
  end

 # Change order status on Qoo10 market place when status changes on FBA
  def change_order_status_on_qsm(mp)
    orders = Spree::Order.where("market_place_id=? AND fulflmnt_state IN (?)", mp.id, ['rfp', 'picked_up'])
    orders.each do |order|
      smp = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=?", order.seller.id, mp.id) rescue nil
      if smp.present?
        uri = URI(mp.domain_url+'/ShippingBasicService.api/SetSendingInfo')
        req = Net::HTTP::Post.new(uri.path)
        req.set_form_data({'key'=>smp.first.api_secret_key,'OrderNo'=>order.market_place_order_no,'ShippingCorp'=>'Fulfillment By Anchanto','TrackingNo'=>order.fulflmnt_tracking_no})
        res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end
      end
      return res && res.code == "200" ? "success" : "failed"
    end
  end

 # Change order status on Lazada market place when status changes on FBA
  def change_order_status_on_lazada(mp)
    @res = []
    orders = Spree::Order.where("market_place_id=? AND fulflmnt_state IN (?) AND market_place_order_status IN (?)", mp.id, ['packup', 'completed', 'assign_for_repicking', 'delivery', 'assign_for_packup', "picked_delivery", "dispatch_queue", "no_show"], ['pending'])
    orders.each do |order|
      smp = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=?", order.seller.id, mp.id) rescue nil
      if smp.present?
        @res << ApiJob.order_state_to_rts_lazada(order.id)
      end
      return @res.present? ? @res.join("; ") : "Success"
    end
  end

  # Method to update all seller stock
  def update_stock_for_seller(seller, fetch_fba_qty)
    stock_values = {}
    inf_variant_ids = Spree::QuantityInflation.pluck(:variant_id)
    var_ids = Spree::Variant.where(:id=>inf_variant_ids).pluck(:product_id)
    # products = inf_variant_ids.present? ? (seller.products.where("is_approved=true AND kit_id IS NULL").where("id NOT IN (?)", var_ids)) : (seller.products.where("is_approved=true AND kit_id IS NULL"))
    products = inf_variant_ids.present? ? (seller.products.where("is_approved=true").where("id NOT IN (?)", var_ids)) : (seller.products.where("is_approved=true"))
    products.each do |product|
      variants = []
      variants << (product.variants.present? ? product.variants : product.master)
      variants = variants.flatten
      type = STOCKCONFIG[product.stock_config_type] == "default" ? STOCKCONFIG[seller.stock_config_type] : STOCKCONFIG[product.stock_config_type]
      smps = seller.seller_market_places.where(:is_active=>true)
      mps = seller.market_places.where("spree_market_places.id IN (?)", smps.map(&:market_place_id))
      variants.each do |variant|
        begin
          Spree::Variant.fetch_qty_from_fba(smps.first,variant) if fetch_fba_qty
          variant = variant.reload
          stock_products = variant.stock_products.where("sellers_market_places_product_id IN (?)", product.sellers_market_places_products.where("market_place_id IN (?)",smps.map(&:market_place_id)).map(&:id))
          if stock_products.present?
            case type
              when "fixed_quantity"
                stock_values.merge!(variant.id=>Spree::StockProduct.fixed_quantity_setting(stock_products, variant, mps)) if !fetch_fba_qty
              when "percentage_quantity"
                stock_values.merge!(variant.id=>Spree::StockProduct.fixed_quantity_setting(stock_products, variant, mps))
                #stock_values.merge!(variant.id=>Spree::StockProduct.percentage_quantity_setting(stock_products, variant, mps))
              when "flat_quantity"
                stock_values.merge!(variant.id=>Spree::StockProduct.flat_quantity_setting(stock_products, variant, mps))
            end # end of case
          end
        rescue Exception => e
        end
      end # end of variant loop
    end # end of product loop
    return update_stock_market_places(stock_values)
  end

  # Method to update stock to market places
  def update_stock_market_places(product_stocks)
    messages = []
    lazada_stock_hash = {}
    zalora_stock_hash = {}
    product_stocks.each do |key, value|
      variant = Spree::Variant.find(key)
      begin
        value.each do |sp_key, stock_count|
          stock_product = Spree::StockProduct.find(sp_key)
          smpp = stock_product.sellers_market_places_product
          market_place = smpp.market_place
          user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", smpp.seller_id, market_place.id)
          case market_place.code
            when "qoo10"
              res = Spree::StockMovement.stock_update_qoo10(variant.product, market_place.id, stock_count, stock_product, user_market_place.first, smpp, stock_count)
            when "lazada"
              if lazada_stock_hash[user_market_place.first.id.to_s].present?
                lazada_stock_hash[user_market_place.first.id.to_s].first.merge!(variant.sku.to_s=>stock_count)
              else
                lazada_stock_hash.merge!(user_market_place.first.id.to_s=>[{variant.sku.to_s=>stock_count}])
              end
            when "zalora"
              if zalora_stock_hash[user_market_place.first.id.to_s].present?
                zalora_stock_hash[user_market_place.first.id.to_s].first.merge!(variant.sku.to_s=>stock_count)
              else
                zalora_stock_hash.merge!(user_market_place.first.id.to_s=>[{variant.sku.to_s=>stock_count}])
              end
          end
          messages << (market_place.name+": "+ res) if res.present? && res != true
        end
      rescue Exception => e
        messages << e.message
      end
    end # end of stock product loop
    # Update stock for lazada in bulk
    Spree::StockMovement.stock_update_lazada_bulk(lazada_stock_hash) if lazada_stock_hash.present?
    Spree::StockMovement.stock_update_lazada_bulk(zalora_stock_hash) if zalora_stock_hash.present?
    return messages.present? ? "fail" : "success"
  end

  # Method to product stock manage according setting
  def stock_manage_with_type(product, seller_market_place_stock_config_details, type)
    stock_values = {}
    variants = []
    variants << (product.variants.present? ? product.variants : product.master)
    variants = variants.flatten
    type = (type == "default" ? STOCKCONFIG[product.seller.stock_config_type] : type)
    mps = []
    seller_market_place_stock_config_details.each do |key, value|
      smpp = Spree::SellersMarketPlacesProduct.find(key)
      smpp.update_column(:stock_config_details,value) if smpp.present?
      smpp = smpp.reload
      mps << smpp.market_place
    end if seller_market_place_stock_config_details.present?
    variants.each do |variant|
      begin
        stock_products = variant.stock_products.where("sellers_market_places_product_id IN (?)",seller_market_place_stock_config_details.keys)
        if stock_products.present?
          case type
            when "fixed_quantity"
              stock_values.merge!(variant.id=>Spree::StockProduct.fixed_quantity_setting(stock_products, variant, mps))
            when "percentage_quantity"
              stock_values.merge!(variant.id=>Spree::StockProduct.fixed_quantity_setting(stock_products, variant, mps))
              #stock_values.merge!(variant.id=>Spree::StockProduct.percentage_quantity_setting(stock_products, variant, mps))
            when "flat_quantity"
              stock_values.merge!(variant.id=>Spree::StockProduct.flat_quantity_setting(stock_products, variant, mps))
          end # end of case
        end
      rescue Exception => e
      end
    end # end of Variant loop
    return stock_values
  end

  # Seller weekly report for current stock
  def seller_weekly_report_current_stock(seller)
    seller_hash = {}
    final_arr = []
    usable_stock = 0
    unusable_stock = 0
    cost_usable_stock = 0.0
    cost_unusable_stock = 0.0
    products = seller.products.where(:is_approved=>true)
    products.each do |product|
      variants = []
      variants << (product.variants.present? ? product.variants : product.master)
      variants = variants.flatten
      variants.each do |variant|
        usable_stock = usable_stock + variant.fba_quantity.to_i
        unusable_stock = unusable_stock + 0
        cost_usable_stock = cost_usable_stock + (variant.cost_price.to_f * variant.fba_quantity.to_i).to_f
        cost_unusable_stock = cost_unusable_stock + 0.0
        arr = []
        arr << product.seller.name
        arr << variant.sku
        arr << variant.cost_price.to_f
        arr << variant.fba_quantity.to_i
        arr << 0
        arr << (variant.cost_price.to_f * variant.fba_quantity.to_i rescue 1).to_f rescue 'NA'
        arr << 0
        arr << variant.name
        final_arr << arr
      end
    end
    seller_hash.merge!("products"=>final_arr, "usable_stock"=>usable_stock, "unusable_stock"=>unusable_stock, "cost_usable_stock"=>cost_usable_stock, "cost_unusable_stock"=>cost_unusable_stock)
    return seller_hash
  end

   # Seller weekly report for stock sales
  def seller_weekly_report_stock_sale(seller)
    seller_hash = {}
    final_arr = []
    us_week = 0
    s_week = 0.0
    us_month = 0
    s_month = 0.0
    us_year = 0
    s_year = 0.0
    products = seller.products.where(:is_approved=>true)
    products.each do |product|
      start_week=(Time.zone.now - 1.week).beginning_of_week
      end_week=(Time.zone.now - 1.week).end_of_week
      start_month=Time.zone.now.beginning_of_month
      end_month=Time.zone.now.end_of_month
      start_year=Time.zone.now.beginning_of_year
      end_year=Time.zone.now.end_of_year
      line_items_week = Spree::LineItem.includes("order").where("spree_orders.is_cancel=false").where(:spree_orders=>{:order_date=>start_week..end_week})
      line_items_month = Spree::LineItem.includes("order").where("spree_orders.is_cancel=false").where(:spree_orders=>{:order_date=>start_month..end_month})
      line_items_year = Spree::LineItem.includes("order").where("spree_orders.is_cancel=false").where(:spree_orders=>{:order_date=>start_year..end_year})
      variants = []
      variants << (product.variants.present? ? product.variants : product.master)
      variants = variants.flatten
      variants.each do |variant|
        v_qty_week = line_items_week.where(:variant_id=>variant.id).sum(&:quantity)
        v_sale_week = (line_items_week.where(:variant_id=>variant.id).sum(&:quantity) * variant.price.to_f).to_f
        v_qty_month = line_items_month.where(:variant_id=>variant.id).sum(&:quantity)
        v_sale_month = (line_items_month.where(:variant_id=>variant.id).sum(&:quantity) * variant.price.to_f).to_f
        v_qty_year = line_items_year.where(:variant_id=>variant.id).sum(&:quantity)
        v_sale_year = (line_items_year.where(:variant_id=>variant.id).sum(&:quantity) * variant.price.to_f).to_f
        us_week = us_week + v_qty_week
        s_week = s_week + v_sale_week
        us_month = us_month + v_qty_month
        s_month = s_month + v_sale_month
        us_year = us_year + v_qty_year
        s_year = s_year + v_sale_year
        arr = []
        arr << product.seller.name
        arr << variant.sku
        arr << variant.price.to_f
        arr << v_qty_week
        arr << v_sale_week
        arr << v_qty_month
        arr << v_sale_month
        arr << v_qty_year
        arr << v_sale_year
        arr << variant.name
        final_arr << arr
      end
    end
    seller_hash.merge!("products"=>final_arr, "units_sold_week"=>us_week, "sale_week"=>s_week, "units_sold_month"=>us_month, "sale_month"=>s_month, "units_sold_year"=>us_year, "sale_year"=>s_year)
    return seller_hash
  end

  # Seller weekly report for orders
  def seller_weekly_report_orders(seller)
    start_week=(Time.zone.now - 1.week).beginning_of_week
    end_week=(Time.zone.now - 1.week).end_of_week
    seller_hash = {}
    final_arr = []
    orders = seller.orders.where(:order_date=>start_week..end_week).where(:is_cancel=>false)
    total_order_value = orders.sum(&:total).to_f
    total_unit_sold = 0
    total_orders = orders.count
    orders.each do |order|
      line_items = order.line_items
      if line_items.present?
        total_unit_sold = total_unit_sold + line_items.sum(&:quantity).to_i
        expected_price = 0.0
        line_items.each do |li|
          expected_price = expected_price + (li.variant.selling_price*li.quantity)
        end
        arr = []
        arr << seller.name
        arr << order.market_place_order_no
        arr << order.cart_no
        arr << order.order_date.strftime("%d-%m-%Y %T")
        arr << (line_items.first.is_pick_at_store ? "Y" : " ") rescue ''
        if order.market_place.code == "qoo10"
          arr << (order.total.to_f - order.market_place_details["ShippingRate"].to_f)
          arr << order.market_place_details["ShippingRate"]
        else
          arr << order.total
          arr << "NA"
        end
        arr << order.total
        arr << line_items.count
        arr << line_items.sum(&:quantity)
        final_arr << arr
      end
    end
    seller_hash.merge!("orders"=>final_arr, "total_order_value"=>total_order_value, "total_units_sold"=>total_unit_sold, "total_orders"=>total_orders)
    return seller_hash
  end

  # Weekly report of the canceled orders
  def seller_weekly_report_canceled_orders(seller)
    start_week=(Time.zone.now - 1.week).beginning_of_week
    end_week=(Time.zone.now - 1.week).end_of_week
    seller_hash = {}
    final_arr = []
    total_order_value = 0.0
    total_unit_sold = 0
    total_orders = 0
    orders = seller.orders.where(:is_cancel=>true).where(:order_canceled_date=>start_week..end_week)
    orders.each do |order|
      line_items = order.line_items
      total_orders = total_orders + 1
      total_unit_sold = total_unit_sold + line_items.sum(&:quantity).to_i
      total_order_value = total_order_value + order.total.to_f
      arr = []
      arr << seller.name
      arr << order.market_place_order_no
      arr << order.cart_no
      arr << order.order_date.strftime("%d-%m-%Y %T")
      arr << (line_items.first.is_pick_at_store ? "Y" : " ") rescue ' '
      arr << order.total
      arr << line_items.count
      arr << line_items.sum(&:quantity)
      arr << " "
      final_arr << arr
    end
    seller_hash.merge!("orders"=>final_arr, "total_order_value"=>total_order_value, "total_units_sold"=>total_unit_sold, "total_orders"=>total_orders)
    return seller_hash
  end

  # Calculate total price with for object line items
  def line_items_price_calculations(line_items)
    total_price = 0.0
    line_items.each do |li|
      total_price += (li.quantity * li.price.to_f)
    end
    return total_price
  end

  # Weekly report summary
  def weekly_report_summary
    @excel_hash = {}
    report_summary = []
    sales_report = []
    cart_report = []
    stock_sold_report = []
    current_stock_report = []

    # Dates
    week1_s = (Time.zone.now - 1.week).beginning_of_week
    week1_e = (Time.zone.now - 1.week).end_of_week
    week2_s = (Time.zone.now - 2.week).beginning_of_week
    week2_e = (Time.zone.now - 2.week).end_of_week
    week3_s = (Time.zone.now - 3.week).beginning_of_week
    week3_e = (Time.zone.now - 3.week).end_of_week
    week4_s = (Time.zone.now - 4.week).beginning_of_week
    week4_e = (Time.zone.now - 4.week).end_of_week
    week5_s = (Time.zone.now - 5.week).beginning_of_week
    week5_e = (Time.zone.now - 5.week).end_of_week
    month1_s = Time.zone.now.beginning_of_month
    month1_e = Time.zone.now.end_of_month
    month2_s = (Time.zone.now - 1.month).beginning_of_month
    month2_e = (Time.zone.now - 1.month).end_of_month
    month3_s = (Time.zone.now - 2.month).beginning_of_month
    month3_e = (Time.zone.now - 2.month).end_of_month
    month4_s = (Time.zone.now - 3.month).beginning_of_month
    month4_e = (Time.zone.now - 3.month).end_of_month
    start_year=Time.zone.now.beginning_of_year
    end_year=Time.zone.now.end_of_year

    # Header
    sales_report << ["","","","Channel Manager Report Summary"]
    sales_report << []
    sales_report << ["Sales Report"]
    sales_report << []
    sales_report << ["Company Total Sale ($)", week4_e.strftime("%d %h'%y"), week3_e.strftime("%d %h'%y"), week2_e.strftime("%d %h'%y"), week1_e.strftime("%d %h'%y"), month3_e.strftime("%h'%y"), month2_e.strftime("%h'%y"), month1_e.strftime("%h'%y"), "YTD"]
    cart_report << []
    cart_report << []
    cart_report << ["Cart Report"]
    cart_report << []
    cart_report << ["Total Carts", week4_e.strftime("%d %h'%y"), week3_e.strftime("%d %h'%y"), week2_e.strftime("%d %h'%y"), week1_e.strftime("%d %h'%y"), month3_e.strftime("%h'%y"), month2_e.strftime("%h'%y"), month1_e.strftime("%h'%y"), "YTD"]
    stock_sold_report << []
    stock_sold_report << []
    stock_sold_report << ["Stock Sold Report"]
    stock_sold_report << []
    stock_sold_report << ["Total Units Sold", week4_e.strftime("%d %h'%y"), week3_e.strftime("%d %h'%y"), week2_e.strftime("%d %h'%y"), week1_e.strftime("%d %h'%y"), month3_e.strftime("%h'%y"), month2_e.strftime("%h'%y"), month1_e.strftime("%h'%y"), "YTD"]
    current_stock_report << []
    current_stock_report << []
    current_stock_report << ["Current Stock Report"]
    current_stock_report << []
    current_stock_report << ["Stock in Hand", "Total Products", "Total Units", "Total Cost of Goods"]
    # Initialise object for total
    week5_total_sale = 0.0
    week4_total_sale = 0.0
    week3_total_sale = 0.0
    week2_total_sale = 0.0
    week1_total_sale = 0.0
    month4_total_sale = 0.0
    month3_total_sale = 0.0
    month2_total_sale = 0.0
    month1_total_sale = 0.0
    year_total_sale = 0.0
    year_cogs = 0.0
    month3_cogs = 0.0
    month2_cogs = 0.0
    month1_cogs = 0.0
    week4_cogs = 0.0
    week3_cogs = 0.0
    week2_cogs = 0.0
    week1_cogs = 0.0
    week5_total_cart = 0
    week4_total_cart = 0
    week3_total_cart = 0
    week2_total_cart = 0
    week1_total_cart = 0
    month4_total_cart = 0
    month3_total_cart = 0
    month2_total_cart = 0
    month1_total_cart = 0
    year_total_cart = 0
    week5_total_stock_sold = 0
    week4_total_stock_sold = 0
    week3_total_stock_sold = 0
    week2_total_stock_sold = 0
    week1_total_stock_sold = 0
    month4_total_stock_sold = 0
    month3_total_stock_sold = 0
    month2_total_stock_sold = 0
    month1_total_stock_sold = 0
    year_total_stock_sold = 0

    # Seller Data
    sellers = Spree::Seller.where(:is_active=>true)
    sellers.each do |seller|
      # Order Data
      year_orders = seller.orders.includes(:line_items=>[:variant]).where(:order_date=>start_year..end_year).where(:is_cancel=>false)
      month4_orders = seller.orders.includes(:line_items=>[:variant]).where(:order_date=>month4_s..month4_e).where(:is_cancel=>false)
      month3_orders = seller.orders.includes(:line_items=>[:variant]).where(:order_date=>month3_s..month3_e).where(:is_cancel=>false)
      month2_orders = seller.orders.includes(:line_items=>[:variant]).where(:order_date=>month2_s..month2_e).where(:is_cancel=>false)
      month1_orders = seller.orders.includes(:line_items=>[:variant]).where(:order_date=>month1_s..month1_e).where(:is_cancel=>false)
      week5_orders = seller.orders.includes(:line_items=>[:variant]).where(:order_date=>week5_s..week5_e).where(:is_cancel=>false)
      week4_orders = seller.orders.includes(:line_items=>[:variant]).where(:order_date=>week4_s..week4_e).where(:is_cancel=>false)
      week3_orders = seller.orders.includes(:line_items=>[:variant]).where(:order_date=>week3_s..week3_e).where(:is_cancel=>false)
      week2_orders = seller.orders.includes(:line_items=>[:variant]).where(:order_date=>week2_s..week2_e).where(:is_cancel=>false)
      week1_orders = seller.orders.includes(:line_items=>[:variant]).where(:order_date=>week1_s..week1_e).where(:is_cancel=>false)
      # Order sales total
      week5_sale = week5_orders.sum(&:total).to_f
      week4_sale = week4_orders.sum(&:total).to_f
      week3_sale = week3_orders.sum(&:total).to_f
      week2_sale = week2_orders.sum(&:total).to_f
      week1_sale = week1_orders.sum(&:total).to_f
      month4_sale = month4_orders.sum(&:total).to_f
      month3_sale = month3_orders.sum(&:total).to_f
      month2_sale = month2_orders.sum(&:total).to_f
      month1_sale = month1_orders.sum(&:total).to_f
      year_sale = year_orders.sum(&:total).to_f
      # Order sales all company total
      week5_total_sale += week5_sale
      week4_total_sale += week4_sale
      week3_total_sale += week3_sale
      week2_total_sale += week2_sale
      week1_total_sale += week1_sale
      month4_total_sale += month4_sale
      month3_total_sale += month3_sale
      month2_total_sale += month2_sale
      month1_total_sale += month1_sale
      year_total_sale += year_sale
      # COGS of orders
      year_cogs += Spree::Seller.get_orders_cogs(year_orders)
      month3_cogs += Spree::Seller.get_orders_cogs(month3_orders)
      month2_cogs += Spree::Seller.get_orders_cogs(month2_orders)
      month1_cogs += Spree::Seller.get_orders_cogs(month1_orders)
      week4_cogs += Spree::Seller.get_orders_cogs(week4_orders)
      week3_cogs += Spree::Seller.get_orders_cogs(week3_orders)
      week2_cogs += Spree::Seller.get_orders_cogs(week2_orders)
      week1_cogs += Spree::Seller.get_orders_cogs(week1_orders)
      sales_report << [seller.name.upcase, week4_sale, week3_sale, week2_sale, week1_sale, month3_sale, month2_sale, month1_sale, year_sale]

      # Unique carts
      year_carts = year_orders.map(&:cart_no).uniq.count
      month4_carts = month4_orders.map(&:cart_no).uniq.count
      month3_carts = month3_orders.map(&:cart_no).uniq.count
      month2_carts = month2_orders.map(&:cart_no).uniq.count
      month1_carts = month1_orders.map(&:cart_no).uniq.count
      week5_carts = week5_orders.map(&:cart_no).uniq.count
      week4_carts = week4_orders.map(&:cart_no).uniq.count
      week3_carts = week3_orders.map(&:cart_no).uniq.count
      week2_carts = week2_orders.map(&:cart_no).uniq.count
      week1_carts = week1_orders.map(&:cart_no).uniq.count
      # Unique carts total
      year_total_cart += year_carts
      month4_total_cart += month4_carts
      month3_total_cart += month3_carts
      month2_total_cart += month2_carts
      month1_total_cart += month1_carts
      week5_total_cart += week5_carts
      week4_total_cart += week4_carts
      week3_total_cart += week3_carts
      week2_total_cart += week2_carts
      week1_total_cart += week1_carts
      cart_report << [seller.name.upcase, week4_carts, week3_carts, week2_carts, week1_carts, month3_carts, month2_carts, month1_carts, year_carts]

      # Stock Sold
      year_stock_sold = year_orders.map(&:line_items).flatten.sum(&:quantity)
      month4_stock_sold = month4_orders.map(&:line_items).flatten.sum(&:quantity)
      month3_stock_sold = month3_orders.map(&:line_items).flatten.sum(&:quantity)
      month2_stock_sold = month2_orders.map(&:line_items).flatten.sum(&:quantity)
      month1_stock_sold = month1_orders.map(&:line_items).flatten.sum(&:quantity)
      week5_stock_sold = week5_orders.map(&:line_items).flatten.sum(&:quantity)
      week4_stock_sold = week4_orders.map(&:line_items).flatten.sum(&:quantity)
      week3_stock_sold = week3_orders.map(&:line_items).flatten.sum(&:quantity)
      week2_stock_sold = week2_orders.map(&:line_items).flatten.sum(&:quantity)
      week1_stock_sold = week1_orders.map(&:line_items).flatten.sum(&:quantity)
      # Stock sold total
      year_total_stock_sold += year_stock_sold
      month4_total_stock_sold += month4_stock_sold
      month3_total_stock_sold += month3_stock_sold
      month2_total_stock_sold += month2_stock_sold
      month1_total_stock_sold += month1_stock_sold
      week5_total_stock_sold += week5_stock_sold
      week4_total_stock_sold += week4_stock_sold
      week3_total_stock_sold += week3_stock_sold
      week2_total_stock_sold += week2_stock_sold
      week1_total_stock_sold += week1_stock_sold
      stock_sold_report << [seller.name.upcase, week4_stock_sold, week3_stock_sold, week2_stock_sold, week1_stock_sold, month3_stock_sold, month2_stock_sold, month1_stock_sold, year_stock_sold]

      # Current Stock
      products = seller.products.includes(:variants).where(:is_approved=>true)
      product_details = Spree::Seller.get_available_stock(products)
      current_stock_report << [seller.name.upcase, products.count, product_details["units"], product_details["cost_price"]]
    end
    sales_report << ["Total", week4_total_sale, week3_total_sale, week2_total_sale, week1_total_sale, month3_total_sale, month2_total_sale, month1_total_sale, year_total_sale]
    # Get percentage sales data
    sale_perc_week4 = Spree::Seller.get_percentage(week5_total_sale,week4_total_sale)
    sale_perc_week3 = Spree::Seller.get_percentage(week4_total_sale,week3_total_sale)
    sale_perc_week2 = Spree::Seller.get_percentage(week3_total_sale,week2_total_sale)
    sale_perc_week1 = Spree::Seller.get_percentage(week2_total_sale,week1_total_sale)
    sale_perc_month3 = Spree::Seller.get_percentage(month4_total_sale,month3_total_sale)
    sale_perc_month2 = Spree::Seller.get_percentage(month3_total_sale,month2_total_sale)
    sale_perc_month1 = Spree::Seller.get_percentage(month2_total_sale,month1_total_sale)
    sales_report << ["% Change", sale_perc_week4, sale_perc_week3, sale_perc_week2, sale_perc_week1, sale_perc_month3, sale_perc_month2, sale_perc_month1, "-"]
    sales_report << []
    sales_report << ["COGS", week4_cogs, week3_cogs, week2_cogs, week1_cogs, month3_cogs, month2_cogs, month1_cogs, year_cogs]
    sales_report << ["Sales - COGS", (week4_total_sale - week4_cogs).round(2), (week3_total_sale - week3_cogs).round(2), (week2_total_sale - week2_cogs).round(2), (week1_total_sale - week1_cogs).round(2), (month3_total_sale - month3_cogs).round(2), (month2_total_sale - month2_cogs).round(2), (month1_total_sale - month1_cogs).round(2), (year_total_sale - year_cogs).round(2)]

    # Cart Data
    cart_report << ["Total", week4_total_cart, week3_total_cart, week2_total_cart, week1_total_cart, month3_total_cart, month2_total_cart, month1_total_cart, year_total_cart]
    # Precentage cart data
    cart_perc_week4 = Spree::Seller.get_percentage(week5_total_cart, week4_total_cart)
    cart_perc_week3 = Spree::Seller.get_percentage(week4_total_cart, week3_total_cart)
    cart_perc_week2 = Spree::Seller.get_percentage(week3_total_cart, week2_total_cart)
    cart_perc_week1 = Spree::Seller.get_percentage(week2_total_cart, week1_total_cart)
    cart_perc_month3 = Spree::Seller.get_percentage(month4_total_cart, month3_total_cart)
    cart_perc_month2 = Spree::Seller.get_percentage(month3_total_cart, month2_total_cart)
    cart_perc_month1 = Spree::Seller.get_percentage(month2_total_cart, month1_total_cart)
    cart_report << ["% Change", cart_perc_week4, cart_perc_week3, cart_perc_week2, cart_perc_week1, cart_perc_month3, cart_perc_month2, cart_perc_month1, "-"]

    # Stock Sold Data
    stock_sold_report << ["Total", week4_total_stock_sold, week3_total_stock_sold, week2_total_stock_sold, week1_total_stock_sold, month3_total_stock_sold, month2_total_stock_sold, month1_total_stock_sold, year_total_stock_sold]
    # Percentage stock sold data
    stock_sold_perc_week4 = Spree::Seller.get_percentage(week5_total_stock_sold, week4_total_stock_sold)
    stock_sold_perc_week3 = Spree::Seller.get_percentage(week4_total_stock_sold, week3_total_stock_sold)
    stock_sold_perc_week2 = Spree::Seller.get_percentage(week3_total_stock_sold, week2_total_stock_sold)
    stock_sold_perc_week1 = Spree::Seller.get_percentage(week2_total_stock_sold, week1_total_stock_sold)
    stock_sold_perc_month3 = Spree::Seller.get_percentage(month4_total_stock_sold, month3_total_stock_sold)
    stock_sold_perc_month2 = Spree::Seller.get_percentage(month3_total_stock_sold, month2_total_stock_sold)
    stock_sold_perc_month1 = Spree::Seller.get_percentage(month2_total_stock_sold, month1_total_stock_sold)
    stock_sold_report << ["% Change", stock_sold_perc_week4, stock_sold_perc_week3, stock_sold_perc_week2, stock_sold_perc_week1, stock_sold_perc_month3, stock_sold_perc_month2, stock_sold_perc_month1, "-"]

    # Excel generation
    report_summary += sales_report
    report_summary += cart_report
    report_summary += stock_sold_report
    report_summary += current_stock_report
    return report_summary
    #@excel_hash.merge!("Report Summary" => report_summary)
    #subject = "[Channel Manager] - Weekly Report"
    #att_name = "Channel_Manager_Weekly_Report_"+Time.now().strftime("%d%m%Y%s").to_s
    #CustomMailer.custom_order_export("abhijeet.ghude@anchanto.com", subject, "Channel Manager Report Summary", helper.generate_excel_multi_worksheet(@excel_hash), att_name).deliver
  end
end