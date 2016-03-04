# Added by Tejaswini Patil
# To create new rule for promotions
# Last modified 1 july 2014

module Spree
  class Promotion
    module Rules
      class ItemCount < Spree::PromotionRule
        preference :count, :integer, :default => 1
        preference :operator, :string, :default => '>'

        attr_accessible :preferred_count, :preferred_operator
        OPERATORS = ['gt', 'gte']

        # This method will set elibility of rule
        def eligible?(order, options = {})
          #item_count = order.line_items.map(&:quantity).sum
          orders = Spree::Order.where(:cart_no => order.cart_no)
          item_count = 0
          orders.each do |ord|
            item_count = item_count +  ord.line_items.where('price > 0').collect{|li| li.quantity }.compact.sum
          end
          # item_count = order.line_items.collect{|li| li.quantity }.compact.sum
          item_count.send(preferred_operator == 'gte' ? :>= : :>,preferred_count)
        end

      end
    end
  end
end