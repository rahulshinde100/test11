module Spree
  LineItem.class_eval do
  	attr_accessible :item_pickup_at, :is_pick_at_store, :picked_up, :stock_location_id, :price, :currency, :ready_for_pickup, :delivery_time, :order_id, :variant_id, :kit_id, :rcp

  	belongs_to :stock_location, :class_name => 'Spree::StockLocation'
  	belongs_to :kit
      #validates :quantity, :numericality => { :less_than_or_equal_to => 10 }

    def copy_price
      if variant
        self.price = variant.price if price.nil?
        self.currency = variant.currency if currency.nil?
      end
    end

    def one_day_shipping?
      if self.item_pickup_at.present? && self.is_pick_at_store.nil?
        return true
      end
      return false
    end

    def get_stock_locations
      self.variant.stock_items.where("count_on_hand > 0").collect{|stock_item| stock_item.stock_location if stock_item.stock_location.is_warehouse && stock_item.stock_location.active}
    end

  end
end
