module Spree
  class OptionTypesMarketPlace < ActiveRecord::Base
    attr_accessible :option_type_id, :market_place_id, :name

    belongs_to :market_place
    belongs_to :option_type

  end
end