module Spree
  class PriceManagement < ActiveRecord::Base
    attr_accessible :selling_price, :special_price, :settlement_price, :market_place_id, :variant_id, :is_active

    belongs_to :market_place, class_name: 'Spree::MarketPlace'
    belongs_to :variant, class_name: 'Spree::Variant'
    
    default_scope { where(is_active: true) }

    validates_presence_of :selling_price, :market_place_id, :variant_id

    validates_numericality_of :special_price, :less_than_or_equal_to => :selling_price, :allow_blank => true
    validates_numericality_of :settlement_price, :less_than_or_equal_to => :selling_price, :allow_blank => true
    after_update :check_updated_fields

    def check_updated_fields
      product = self.variant.product
      desc = !new_record? ? ProductJob.get_updated_fields(self.changed,self.market_place.code) : 'new_price'
      # RecentMarketPlaceChange.create!(:varient_id => self.variant.id,:product_id => product.id,:seller_id => product.seller_id, :market_place_id => self.market_place_id, :description => desc.join(','), :update_on_fba=>false)
      self.variant.recent_market_place_changes.create!(:product_id => product.id,:seller_id => product.seller_id, :market_place_id => self.market_place_id, :description => desc.join(','), :update_on_fba=>false) if desc.present?

    end
  end
end
