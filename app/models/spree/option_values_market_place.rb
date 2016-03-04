class Spree::OptionValuesMarketPlace < ActiveRecord::Base
  attr_accessible :option_type_id, :market_place_id,:option_value_id, :name

  belongs_to :market_place
  belongs_to :option_type
  belongs_to :option_value

end
