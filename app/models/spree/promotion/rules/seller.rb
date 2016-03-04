module Spree
  class Promotion
    module Rules
      class Seller < PromotionRule
        attr_accessible :seller_ids_string

        # if Spree::seller_class_eval
        #   belongs_to :seller, class_name: Spree.seller_class.to_s
        #   has_and_belongs_to_many :sellers, class_name: Spree.seller_class.to_s, join_table: 'spree_promotion_rules_sellers', foreign_key: 'promotion_rule_id'
        # else
          belongs_to :seller
          has_and_belongs_to_many :sellers, join_table: 'spree_promotion_rules_sellers', foreign_key: 'promotion_rule_id', :class_name => Spree::Seller
        # end

        def eligible_sellers
          sellers
        end
        def eligible?(order, options = {})
          return false if eligible_sellers.empty?
          orders = Spree::Order.where(:cart_no => order.cart_no)
          order_sellers = orders.map(&:seller)
          result = false
          eligible_sellers.each do |seller|
            result = true if order_sellers.include?(seller)
          end
          return result
        end

        def seller_ids_string
          seller_ids.join(',')
        end

        def seller_ids_string=(s)
          self.seller_ids = s.to_s.split(',').map(&:strip)
        end
      end
    end
  end
end
