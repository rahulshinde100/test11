module Spree
  class MpOrderLineItem < ActiveRecord::Base
    attr_accessible :order_id, :market_place_details
    serialize :market_place_details, JSON
    
    belongs_to :order
    
    validates :order_id, presence: true
    
  end
end
