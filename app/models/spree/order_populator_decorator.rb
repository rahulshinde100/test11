Spree::OrderPopulator.class_eval do

	def populate(from_hash)
    from_hash[:products].each do |product_id,variant_id|
      attempt_cart_add(variant_id, from_hash[:quantity], from_hash[:is_pickup]["is_pick_at_store_#{variant_id}"], from_hash[:stock_location]["stock_location_#{variant_id}"])
    end if from_hash[:products]

    from_hash[:variants].each do |variant_id, quantity|
      attempt_cart_add(variant_id, quantity, from_hash[:is_pickup]["is_pick_at_store_#{variant_id}"], from_hash[:stock_location]["stock_location_#{variant_id}"])
    end if from_hash[:variants]


    valid?
  end

  private
    def attempt_cart_add(variant_id, quantity, is_pick_at_store, stock_location_id)
      # quantity = quantity.to_i
      # # 2,147,483,647 is crazy.
      # # See issue #2695.
      # if quantity > 2_147_483_647
      #   errors.add(:base, Spree.t(:please_enter_reasonable_quantity, :scope => :order_populator))
      #   return false
      # end
      # variant = Spree::Variant.find(variant_id)
      # if quantity > 0
      #   item = order.find_line_item_by_variant_and_is_pick_at_store(variant,(is_pick_at_store == 'true' ? true : false))
      #   prev_quantity = item.quantity if item
      #   if variant.in_stock?(quantity + item.try(:quantity).to_i)
      #     line_item = @order.contents.add(variant, quantity, currency, is_pick_at_store, stock_location_id)

      #     unless line_item.valid?
      #       errors.add(:base, line_item.errors.messages.values.join(" "))
      #       return false
      #     end

      #     if item
      #       puts prev_quantity
      #       puts line_item.quantity
      #       if line_item.quantity == prev_quantity
      #         errors.add(:base, line_item.errors.messages.values.join(" "))
      #         return false
      #       end
      #       if (prev_quantity + quantity.to_i).abs > Spree::Config[:cart_item_limit].to_i
      #         errors.add(:base, line_item.errors.messages.values.join(" "))
      #         return false
      #       end
      #     else
      #       if line_item.quantity > quantity.to_i && (line_item.quantity + quantity.to_i + 1).abs > Spree::Config[:cart_item_limit].to_i
      #         errors.add(:base, line_item.errors.messages.values.join(" "))
      #         return false
      #       end
      #       if line_item.quantity < quantity.to_i && (line_item.quantity + quantity.to_i).abs > Spree::Config[:cart_item_limit].to_i
      #         errors.add(:base, line_item.errors.messages.values.join(" "))
      #         return false
      #       end
      #     end
      #   else
      #     errors.add(:base, "Out of Stock")
      #     return false
      #   end
      # end
    end
end
