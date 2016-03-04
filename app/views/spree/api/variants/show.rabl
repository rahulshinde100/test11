object @variant
extends "spree/api/variants/variant"
child(:option_values => :option_values) { attributes *option_value_attributes }
child(:stock_items => :stock_items) do |item|
    attributes :id, :count_on_hand, :variant_id, :stock_location_name, :stock_location_id
end
child(:images => :images) { extends "spree/api/images/show" }