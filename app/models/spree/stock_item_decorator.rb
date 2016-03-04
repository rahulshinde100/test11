module Spree
  StockItem.class_eval do
    attr_accessible :virtual_out_of_stock, :stock_location_name

    validates_numericality_of :count_on_hand, :only_integer => true, :greater_than_or_equal_to => 0, :message => "Stock Can't be Negative"
    def in_stock?
      self.count_on_hand > 0 && !self.virtual_out_of_stock?
    end

    def stock_location_name
      self.stock_location.try(:name)
    end
  end
end