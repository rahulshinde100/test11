module Spree
  class MarketPlace < ActiveRecord::Base
    attr_accessible :code, :id, :name, :domain_url
    has_many :orders
    has_many :sellers_market_places
    has_many :recent_market_place_changes, :class_name => "Spree::RecentMarketPlaceChange", :dependent => :destroy
    has_many :quantity_inflations
    
    scope :return_market_place, lambda{|name| where(:name => name)}
  end
end
