object @prototypes
attributes :id,:name

child :option_types => :option_types do
	attribute *option_type_attributes
	child :option_values => :option_values do
		attributes *option_value_attributes
	end
end

child :properties => :properties do
	attribute :id,:name
end
