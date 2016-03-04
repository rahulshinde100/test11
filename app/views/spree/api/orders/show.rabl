object @order
extends "spree/api/orders/order"

child :billing_address => :bill_address do
  extends "spree/api/addresses/show"
end

child :shipping_address => :ship_address do
  extends "spree/api/addresses/show"
end

child :line_items => :line_items do
  attributes *line_item_attributes
  node(:single_display_amount) { |li| li.single_display_amount.to_s }
  node(:display_amount) { |li| li.display_amount.to_s }
  node(:total) { |li| li.total }
  child :variant do
    attributes *variant_attributes
    node(:options_text) { |v| v.options_text }
    child :option_values => :option_values do
      attributes *option_value_attributes
    end

    child(:stock_items) do
      attributes :id, :count_on_hand, :stock_location_id, :backorderable
      attribute :available? => :available

      child :stock_location do
         attributes *stock_location_attributes
      end
    end
    attributes :product_id
    child(:images => :images) { extends "spree/api/images/show" }
  end
end

child :payments => :payments do
  attributes :id, :amount, :state, :payment_method_id
  child :payment_method => :payment_method do
    attributes :id, :name, :environment
  end
end

child :shipments => :shipments do
  extends "spree/api/shipments/show"
end

child :adjustments => :adjustments do
  extends "spree/api/adjustments/show"
end

child :credit_cards => :credit_cards do
  extends "spree/api/credit_cards/show"
end