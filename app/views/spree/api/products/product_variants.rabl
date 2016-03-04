object @variants
attributes *variant_attributes
child :option_values => :option_values do
    attributes *option_value_attributes
end
child(:stock_items => :stock_items) do |item|
    attributes :id, :count_on_hand, :variant_id, :stock_location_name, :stock_location_id
end
child(:images => :images) do
    attributes *image_attributes
    code(:urls) do |v|
      v.attachment.styles.keys.inject({}) { |urls, style| urls[style] = v.attachment.url(style); urls }
    end
end