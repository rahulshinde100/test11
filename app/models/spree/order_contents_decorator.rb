module Spree
	OrderContents.class_eval do
		def add(variant, quantity, currency=nil, shipment=nil, is_pick_at_store, stock_location_id)
      line_item = order.find_line_item_by_variant_and_is_pick_at_store(variant,(is_pick_at_store == 'true' ? true : false))
      add_to_line_item(line_item, variant, quantity, currency, shipment, is_pick_at_store, stock_location_id)
    end

    def add_to_line_item(line_item, variant, quantity, currency=nil, shipment=nil, is_pick_at_store, stock_location_id)
      if line_item         
        return line_item if (line_item.quantity + quantity.to_i - 1) >= Spree::Config[:cart_item_limit].to_i
        line_item.target_shipment = shipment
        line_item.quantity += quantity.to_i
        line_item.currency = currency unless currency.nil?
        line_item.save
      else
        line_item = LineItem.new(quantity: quantity, is_pick_at_store: is_pick_at_store, stock_location_id: stock_location_id)
        line_item.target_shipment = shipment
        line_item.variant = variant
        if currency
          line_item.currency = currency unless currency.nil?
          line_item.price    = variant.special_price || variant.price_in(currency).amount
          line_item.rcp      = variant.rcp
        else
          line_item.price    = variant.special_price || variant.price
          line_item.rcp      = variant.rcp
        end
        order.line_items << line_item
        line_item
      end

      order.reload
      line_item
    end
	end
end