object @option_types
attributes :id,:name
child :option_values => :option_values do
	attributes *option_value_attributes
end


