module Spree
  class SyncMarketPlaceVariant < ActiveRecord::Base
    attr_accessible :seller_id, :market_place_id, :product_id, :variant_id, :variant_sku

    belongs_to :market_place
    belongs_to :seller
    belongs_to :product
    belongs_to :variant

    validates_presence_of :seller_id, :market_place_id, :product_id, :variant_id, :variant_sku
  end
end
