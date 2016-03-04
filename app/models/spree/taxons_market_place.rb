module Spree
  class TaxonsMarketPlace < ActiveRecord::Base
    attr_accessible :taxon_id, :market_place_id, :name, :market_place_category_id

    belongs_to :market_place
    belongs_to :taxon

    validates_presence_of :market_place_id, :taxon_id, :name, :market_place_category_id
  end
end
