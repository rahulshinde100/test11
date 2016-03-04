module Spree
  class SellersMarketPlacesKit < ActiveRecord::Base
    attr_accessible :seller_id, :market_place_id, :kit_id

    belongs_to :market_place
    belongs_to :seller
    belongs_to :kit

    validates_presence_of :seller_id, :market_place_id, :kit_id
  end
end
