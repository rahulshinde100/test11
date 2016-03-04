module Spree
  module Stock
     Quantifier.class_eval do

      def total_on_hand
        virtual_out_of_stock = false
        stock_items.each do |item|
          if !item.virtual_out_of_stock?
            virtual_out_of_stock = false
            break 
          else
            virtual_out_of_stock = true
          end
        end
        
        if Spree::Config.track_inventory_levels
          virtual_out_of_stock ? 0 : stock_items.sum(&:count_on_hand)
        else
          Float::INFINITY
        end
      end

      def can_supply?(required)
        total_on_hand >= required #|| backorderable?
      end
      
    end
  end
end