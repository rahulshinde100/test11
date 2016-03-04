# A rule to apply to an order greater than (or greater than or equal to)
# a specific amount
module Spree
  class Promotion
    module Rules
      class ItemTotal < Spree::PromotionRule
      preference :amount, :decimal, :default => 100.00
        preference :operator, :string, :default => '>'

        attr_accessible :preferred_amount, :preferred_operator

        OPERATORS = ['gt', 'gte']

        def eligible?(order, options = {})
          item_total = 0
          item_total = Spree::Order.where(:cart_no => order.cart_no).map(&:total).sum
          # Spree::Order.where(:cart_no => order.cart_no).each do |ord|
          #   item_total = item_total +  ord.total
          # end
          # ite m_total = order.line_items.map(&:amount).sum
          item_total.send(preferred_operator == 'gte' ? :>= : :>, BigDecimal.new(preferred_amount.to_s))
        end
      end
    end
  end
end
