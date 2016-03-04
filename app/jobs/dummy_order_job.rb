class DummyOrderJob
  
  def self.create_dummy_order_for_lazada(params, smp)
    Rails.logger.info '--------'
    Rails.logger.info smp
    order = params['Order']
    Rails.logger.info order
    @cart_numbers = []
    items = []
    items <<  params['OrderItem']
    items = items.flatten
    Rails.logger.info items
    @order_items = []
    @order = nil
    @order_status = nil
    message = ""
    cm_user = smp.seller.is_cm_user
    begin
    @order = Spree::Order.where("market_place_order_no=? AND seller_id=?", order['OrderId'], smp.seller_id).try(:first)
    p @order
    if !@order.present?
      Rails.logger.info 'order not present can create'
      Time.zone = "Singapore"
      # current_time = Time.zone.now
      # market_place = smp.market_place
      items[0].each do |item|
        @order_items << item[1]
      end
      @order_items = @order_items.flatten
      @order_status = @order_items[0]['Status']
      p @order_status
      gift = (order['GiftOption'] == "0" ? false : true)
      shipping_country = Spree::Country.find_by_name(order['AddressShipping']['Country'])
      billing_country = Spree::Country.find_by_name(order['AddressBilling']['Country'])
      shipping_last_name = (order['AddressShipping']['LastName'] ? order['AddressShipping']['LastName'] : order['AddressShipping']['FirstName'])
      billing_last_name = (order['AddressBilling']['LastName'] ? order['AddressBilling']['LastName'] : order['AddressBilling']['FirstName'])
      shipping_phone_no = (order['AddressShipping']['Phone'].present? ? order['AddressShipping']['Phone'] : order['AddressShipping']['Phone2'])
      billing_phone_no = (order['AddressBilling']['Phone'].present? ? order['AddressBilling']['Phone'] : order['AddressBilling']['Phone2'])
      @shpping_address = Spree::Address.create!(:firstname=>order['AddressShipping']['FirstName'], :lastname=>shipping_last_name, :address1=>order['AddressShipping']['Address1'], :address2=>order['AddressShipping']['Address2'], :city=>shipping_country.name, :zipcode=>order['AddressShipping']['PostCode'], :phone=>shipping_phone_no, :alternative_phone=>order['AddressShipping']['Phone2'], :country_id=>shipping_country.id, :state_name=>shipping_country.name)
      if !order['AddressBilling']['FirstName'].present? && !order['AddressBilling']['Address1'].present? && !order['AddressBilling']['Country'].present? && !order['AddressBilling']['PostCode'].present? && !order['AddressBilling']['Phone'].present? && !billing_country.nil?
        @billing_address = Spree::Address.create!(:firstname=>order['AddressBilling']['FirstName'], :lastname=>billing_last_name, :address1=>order['AddressBilling']['Address1'], :address2=>order['AddressBilling']['Address2'], :city=>billing_country.name,:zipcode=>order['AddressBilling']['PostCode'], :phone=>billing_phone_no, :alternative_phone=>order['AddressBilling']['Phone2'], :country_id=>billing_country.id, :state_name=>billing_country.name)
      end
      billing_address = (!@billing_address.nil? && !@billing_address.blank?) ? @billing_address.id : nil
      order_item_list = []
      item_total = 0.0
      payment_total = 0.0
      quantity_hash = {}
      price_hash = {}
      @order_items.each do |item|
        # item['Sku'] = 'NEWRKIT'#'TPUSBC'#'NEWRKIT'
        item_total = item_total + item['ItemPrice'].to_f
        payment_total = payment_total + item['PaidPrice'].to_f
        if price_hash[item[:Sku]].present?
          price_hash[item[:Sku]] = price_hash[item[:Sku]].to_f + item[:PaidPrice].to_f
        else 
          price_hash = price_hash.merge(item[:Sku]=>item[:PaidPrice].to_f) 
        end
        if quantity_hash[item['Sku']].present?
          quantity_hash[item['Sku']] = quantity_hash[item['Sku']].to_i + 1
        else
          quantity_hash = quantity_hash.merge(item['Sku']=>1)
          order_item_list << item
        end
      end
      currency = (order_item_list.present? ? order_item_list.first['Currency'] : "SGD")
      @order = Spree::Order.create!(:number=>order['OrderNumber'], :order_date=>order['CreatedAt'], :market_place_details=>order, :item_total=>item_total, :total=>payment_total, :payment_total=>payment_total, :email=>smp.seller.contact_person_email, :currency=>currency, :send_as_gift=>gift, :market_place_id=>smp.market_place_id, :market_place_order_no=>order['OrderId'], :market_place_order_status=>@order_status, :bill_address_id=>billing_address, :ship_address_id=> @shpping_address.id, :cart_no=>order['OrderNumber'], :seller_id=>smp.seller_id, :is_bypass=>!cm_user)
      p order_item_list
      p order_item_list.first['Sku']
      order_item_list.each do |item|
        if cm_user
          p 'cm_user'
          # item['Sku'] ='NEWRKIT'# 'TPUSBC'#
          @variant = nil
          @mp_product = nil
          @line_item = nil
          @stock = nil
          p smp.seller_id
          p item['sku']
          @variant = Spree::Variant.includes(:product).where("spree_products.seller_id=? AND sku=?", smp.seller_id, item['Sku']).try(:first)
          if @variant.present?
            p '------------- v p'
            @mp_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @variant.product.seller_id, smp.market_place_id, @variant.product_id).first
            if @variant.product.kit.present?
              p 'v i kit'
              kit = @variant.product.kit
              l_items = kit.kit_products
              l_items.each do |lt|
                lt_variant = lt.variant
                quantity = lt.quantity*quantity_hash[item['Sku']]
                line_item = Spree::LineItem.create!(:variant_id=>lt_variant.id, :order_id=>@order.id, :quantity=>quantity, :price=>(lt_variant.price*quantity), :currency=>item['Currency'], :kit_id=>kit.id, :rcp=>price_hash[item[:Sku]])
                stock = lt_variant.stock_products.where("sellers_market_places_product_id IN (?)", lt_variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                lt_variant.update_attributes(:fba_quantity=>(lt_variant.fba_quantity - quantity)) if !lt_variant.quantity_inflations.present?
                msg = 'DummyOrderJob create_dummy_order_for_lazada Line 85'
                lt_variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
                stock.update_attributes!(:count_on_hand=>(stock.count_on_hand - quantity) >= 0 ? (stock.count_on_hand - quantity) : 0 ) if stock.present? && !lt_variant.quantity_inflations.present?
              end
            else
              if @variant.parent_id.present?
                @parent =  Spree::Variant.find(@variant.parent_id)
                if @parent.product.kit.present?
                  kit = @parent.product.kit
                  l_items = kit.kit_products
                  l_items.each do |lt|
                    lt_variant = lt.variant
                    quantity = lt.quantity*quantity_hash[item['Sku']]
                    line_item = Spree::LineItem.create!(:variant_id=>lt_variant.id, :order_id=>@order.id, :quantity=>quantity, :price=>(lt_variant.price*quantity), :currency=>item['Currency'], :kit_id=>kit.id, :rcp=>price_hash[item[:Sku]])
                    stock = lt_variant.stock_products.where("sellers_market_places_product_id IN (?)", lt_variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                    lt_variant.update_attributes(:fba_quantity=>(lt_variant.fba_quantity - quantity)) if !lt_variant.quantity_inflations.present?
                    msg = 'DummyOrderJob create_dummy_order_for_lazada Line 100'
                    lt_variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
                    stock.update_attributes!(:count_on_hand=>(stock.count_on_hand - quantity) >= 0 ? (stock.count_on_hand - quantity) : 0 ) if stock.present? && lt_variant.quantity_inflations.present?
                  end
                else
                  @line_item = Spree::LineItem.create!(:variant_id=>@parent.id, :order_id=>@order.id, :quantity=>quantity_hash[item['Sku']], :price=>item['PaidPrice'], :currency=>item['Currency'], :rcp=>price_hash[item[:Sku]])
                  type = (STOCKCONFIG[@parent.product.stock_config_type] == "default" ? STOCKCONFIG[@parent.product.seller.stock_config_type] : STOCKCONFIG[@parent.product.stock_config_type])
                  @parent.update_attributes(:fba_quantity=>(@parent.fba_quantity - quantity_hash[item['Sku']])) if !@parent.quantity_inflations.present?
                  msg = 'DummyOrderJob create_dummy_order_for_lazada Line 108'
                  @parent.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}" if !@parent.quantity_inflations.present?
                  @variant.update_attributes(:fba_quantity=>(@variant.fba_quantity - quantity_hash[item['Sku']])) if !@variant.quantity_inflations.present? && @parent.quantity_inflations.present?
                  msg = 'DummyOrderJob create_dummy_order_for_lazada Line 108'
                  @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}" if !@variant.quantity_inflations.present? && @parent.quantity_inflations.present?
                  if (type != "flat_quantity") || (type == "flat_quantity" && !@parent.product.kit.present?)
                    @stock = @parent.stock_products.where("sellers_market_places_product_id IN (?)", @parent.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                    @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - quantity_hash[item['Sku']]) >= 0 ? (@stock.count_on_hand - quantity_hash[item['Sku']]) : 0 ) if @stock.present? && @parent.quantity_inflations.present?
                  end
                  child_type = (STOCKCONFIG[@variant.product.stock_config_type] == "default" ? STOCKCONFIG[@variant.product.seller.stock_config_type] : STOCKCONFIG[@variant.product.stock_config_type])
                  if (child_type != "flat_quantity") || (child_type == "flat_quantity" && !@variant.product.kit.present?)
                    @stock = @variant.stock_products.where("sellers_market_places_product_id IN (?)", @variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                    @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - quantity_hash[item[:Sku]]) >= 0 ? (@stock.count_on_hand - quantity_hash[item[:Sku]]) : 0 ) if @stock.present? && (@parent.quantity_inflations.present? && @variant.quantity_inflations.present?)
                  end
                end
              else
                @line_item = Spree::LineItem.create!(:variant_id=>@variant.id, :order_id=>@order.id, :quantity=>quantity_hash[item['Sku']], :price=>item['PaidPrice'], :currency=>item['Currency'], :rcp=>price_hash[item[:Sku]])
                type = (STOCKCONFIG[@variant.product.stock_config_type] == "default" ? STOCKCONFIG[@variant.product.seller.stock_config_type] : STOCKCONFIG[@variant.product.stock_config_type])
                @variant.update_attributes(:fba_quantity=>(@variant.fba_quantity - quantity_hash[item['Sku']])) if !@variant.quantity_inflations.present?
                msg = 'DummyOrderJob create_dummy_order_for_lazada Line 127'
                @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}" if !@variant.quantity_inflations.present?
                if (type != "flat_quantity") || (type == "flat_quantity" && !@variant.product.kit.present?)
                  @stock = @variant.stock_products.where("sellers_market_places_product_id IN (?)", @variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                  @stock.update_attributes(:count_on_hand=>(@stock.count_on_hand - quantity_hash[item['Sku']]) >= 0 ? (@stock.count_on_hand - quantity_hash[item['Sku']]) : 0 ) if @stock.present? && @variant.quantity_inflations.present?
                end
              end
            end
          end
        else
          p 'not cm user'
          Spree::MpOrderLineItem.create!(:order_id=>@order.id, :market_place_details=>item)
        end
      end # end of order_item_list
      @order.update_column(:total, payment_total)
      @order.reload
      ActiveSupport::Notifications.instrument('spree.order.contents_changed', {:user => nil, :order => @order})
      # DummyOrderJob.apply_promotion(@order)
      Spree::Order.push_to_fba([order['OrderNumber']])

      @cart_numbers << order['OrderNumber']
    else
      message << 'Order with same number is already present'
      Rails.logger.info 'Order with same number is already present'
    end
    rescue Exception => e
      Rails.logger.info e.message
      message << e.message
    end
    message = 'Order placed succesfully.' if message.blank?
    return message
  end
  
  def self.apply_promotion(order)
    items = order.line_items.count
    ActiveSupport::Notifications.instrument('spree.order.contents_changed', {:user => nil, :order => order})
    order.reload
    if order.line_items.count == items
      return
    else
      apply_promotion(order)
    end
  end

end
