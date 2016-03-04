# Added by Tejaswini Patil
# Decorator for Create Line items on promotion
# Last Modified 7 march 2014

module Spree
    class Promotion
    module Actions
      CreateLineItems.class_eval do

# This method will add an line item to order if the promotion(buy one get one at this cost) is applicable
        def perform(options = {})
if self.promotion.promotion_rules.present?
          order = options[:order]
          if order.present?
            p self.promotion.id
            return unless self.eligible? order
            p 'eligible'
            promotion_action_line_items.each do |item|
              begin
              if item.variant.present?
                qty = item.quantity
                rule =  self.promotion.promotion_rules.where(:type => "Spree::Promotion::Rules::Variant").first rescue nil
                current_quantity = 0
                if rule.present?
                  max_qty,free_added = rule.calculate_qty(order,item)
                  qty = max_qty - free_added
                  qty = qty * item.quantity
                else
                  p 'else'
                  orders = Spree::Order.where(:cart_no => order.cart_no)
                  current_quantity = 0
                  orders.each do |ord|
                    current_quantity = current_quantity + ord.line_items.where(:variant_id => item.variant.id, :price => 0).collect{|li| li.quantity }.compact.sum rescue 0
                  end
                  p current_quantity
                  qty = qty - current_quantity
                end
                if qty > 0
                  # qty = qty * item.quantity
                  smp = Spree::SellerMarketPlace.where(:market_place_id => order.market_place_id, :seller_id => order.seller_id).first rescue nil
                  line_item = Spree::LineItem.create!({:order_id => order.id, :variant_id => item.variant.id, :price => 0, :promotion_discount_price => 0, :is_promotion => true, :quantity => qty})
                  if line_item.present?
                    variant =  item.variant
                    stock = variant.stock_products.where("sellers_market_places_product_id IN (?)", variant.product.sellers_market_places_products.where("market_place_id=?",smp.market_place_id).map(&:id)).first
                    variant.update_attributes(:fba_quantity=>(variant.fba_quantity - qty)) if !variant.quantity_inflations.present?
                    msg = 'Model- line items create'
                    variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
                    stock.update_attributes!(:count_on_hand=>(stock.count_on_hand - qty) >= 0 ? (stock.count_on_hand - qty) : 0 ) if stock.present? && variant.quantity_inflations.present?
                  end
                end
                order.reload
                order.update!
              end
              rescue Exception => e

                end
            end
          end
        end
end
      end
    end
  end
end