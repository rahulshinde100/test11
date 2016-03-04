object @variant
attributes *variant_attributes
extends "spree/api/variants/show"
child(:option_values => :option_values) { attributes *option_value_attributes }
child(:images => :images) { extends "spree/api/images/show" }