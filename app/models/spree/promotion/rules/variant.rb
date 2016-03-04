# A rule to limit a promotion based on variants in the order.
# Can require all or any of the variants to be present.
# Valid variants either come from assigned variant group or are assingned directly to the rule.
module Spree
  class Promotion
    module Rules
      class Variant < PromotionRule
        attr_accessible :variant_ids_string
        has_and_belongs_to_many :variants, :class_name => '::Spree::Variant', :join_table => 'spree_promotion_rules_variants', :foreign_key => 'promotion_rule_id'
        validate :only_one_promotion_per_variant

        MATCH_POLICIES = %w(any all)
        preference :match_policy, :string, :default => MATCH_POLICIES.first
        preference :count, :integer, :default => 1
        # preference :operator, :string, :default => '>'

        attr_accessible :preferred_count#, :preferred_operator
        # OPERATORS = ['gt', 'gte']

        # scope/association that is used to test eligibility
        def eligible_variants
          variants
        end

        def eligible?(order, options = {})
          return false if eligible_variants.empty?
          orders = Spree::Order.where(:cart_no => order.cart_no)
          order_variants = []
          line_items = []
          orders.each do |ord|
            line_items << ord.line_items.where('price > 0')
            line_items = line_items.flatten
            order_variants  << line_items.collect{|li| li.variant }
          end
          order_variants = order_variants.flatten
          p order_variants
          p eligible_variants
          if preferred_match_policy == 'all'
           result =   eligible_variants.all? {|p| order_variants.include?(p) }
           p result
           if result
             eligible_variants.each do |ev|
               item_count = line_items.select{ |a| a.variant_id == ev.id}.collect{|li| li.quantity }.compact.sum rescue 0
               p item_count

               if (item_count < preferred_count)
                 result = false
               end
             end
           end
          else
            result =  eligible_variants.any? {|p| order_variants.include?(p) }
            if result
              eligible_variants.each do |ev|
                item_count = line_items.select{ |a| a.variant_id == ev.id}.collect{|li| li.quantity }.compact.sum
                if item_count >= preferred_count
                  result = true
                end
              end
            end
          end

          p " variant #{result}"
          return result
        end

        def variant_ids_string
          variant_ids.join(',')
        end

        def variant_ids_string=(s)
          self.variant_ids = s.to_s.split(',').map(&:strip)
        end

        def calculate_qty(order,item)
          orders = Spree::Order.where(:cart_no => order.cart_no)
          order_variants = []
          line_items = []
          free_added = 0
          orders.each do |ord|
            line_items << ord.line_items.where('price > 0')
            line_items = line_items.flatten
            free_added = free_added + ord.line_items.where('price = 0').where(:variant_id => item.variant.id).count
          end
          max_qty = 0
          if preferred_match_policy == 'all'
            eligible_variants.each do |ev|
              item_count = line_items.select{ |a| a.variant_id == ev.id}.collect{|li| li.quantity }.compact.sum rescue 0
              if max_qty > item_count || max_qty == 0
                max_qty = item_count
              end
            end
          else
            eligible_variants.each do |ev|
              max_qty = max_qty +  line_items.select{ |a| a.variant_id == ev.id}.collect{|li| li.quantity }.compact.sum rescue 0
            end
          end
          item_qty = preferred_count
          max_qty = max_qty/item_qty
          return max_qty, free_added
        end

        private

        def only_one_promotion_per_variant
          # if Spree::Promotion::Rules::Variant.all.map(&:variants).flatten.uniq!
          if  Spree::Promotion::Rules::Variant.where(:activator_id => Spree::Promotion.on_going_promotions.map(&:id)).map(&:variants).flatten.uniq!
            errors[:base] << "You can't create two promotions for the same variant"
          end
        end
      end
    end
  end
end
