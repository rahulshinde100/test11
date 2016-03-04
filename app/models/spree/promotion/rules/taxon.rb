module Spree
  class Promotion
    module Rules
      class Taxon < PromotionRule
        attr_accessible :taxon_ids_string

        # belongs_to :taxon
        # has_and_belongs_to_many :taxons,
        #                         class_name: '::Spree::Taxon',
        #                         join_table: 'spree_promotion_rules_taxons',
        #                         foreign_key: 'promotion_rule_id'
        belongs_to :taxon
        has_and_belongs_to_many :taxons, join_table: 'spree_promotion_rules_taxons', foreign_key: 'promotion_rule_id', :class_name => Spree::Taxon
        def eligible_taxons
          taxons
        end

        def eligible?(order, options = {})
          return false if eligible_taxons.empty?
          # eligible_taxons.include?(order.taxon)
          orders = Spree::Order.where(:cart_no => order.cart_no)
          order_taxons = []
          orders.each do |ord|
            ord.line_items.where('price > 0').each do |item|
              order_taxons << item.variant.product.taxons rescue ''
            end
            #order_taxons << ord.products.where('price > 0').collect{|p| p.taxons}.flatten
          end
          # eligible_taxons.include?(order.products.collect{|p| p.taxons})
          taxons = eligible_taxons.flatten
          order_taxons = order_taxons.flatten
          match_array =  order_taxons.collect{|p| taxons.include? p}
          return true if match_array.include? true
          return false
          # eligible_taxons.all? {|p| order.products.include?(p) }
        end

        def taxon_ids_string
          taxons_ids.join(',')
        end

        def taxon_ids_string=(s)
          self.taxon_ids = s.to_s.split(',').map(&:strip)
        end
      end
    end
  end
end