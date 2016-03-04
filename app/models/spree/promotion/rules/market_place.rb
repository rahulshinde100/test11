module Spree
  class Promotion
    module Rules
      class MarketPlace < PromotionRule
        attr_accessible :market_place_ids_string

        belongs_to :market_place
        has_and_belongs_to_many :market_places,
                                class_name: '::Spree::MarketPlace',
                                join_table: 'spree_promotion_rules_market_places',
                                foreign_key: 'promotion_rule_id'

        def eligible_market_places
          market_places
        end

        def eligible?(order, options = {})
          return true if eligible_market_places.empty?
          # if preferred_match_policy == 'all'
          #   eligible_products.all? {|p| order.products.include?(p) }
          eligible_market_places.include?(order.market_place)
          # eligible_market_places.all? {|p| order.market_place.include?(p) }
          # else
          #   order.products.any? {|p| eligible_products.include?(p) }
          # end
        end

        # def eligible?(order, options = {})
        #   market_places = order.market_place_id
        #   p market_places
        #   market_places.any?
        #
        #
        # end

        def market_place_ids_string
          market_places_ids.join(',')
        end

        def market_place_ids_string=(s)
          self.market_place_ids = s.to_s.split(',').map(&:strip)
        end
      end
    end
  end
end