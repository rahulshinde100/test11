# Added by Tejaswini Patil
# To manage the recent market place detail changes
# on 25 Aug 2015
class Spree::RecentMarketPlaceChange < ActiveRecord::Base
  attr_accessible :product_id,:variant_id,:market_place_id,:updated_by,:description,:seller_id, :update_on_fba, :deleted_at
  belongs_to :user
  belongs_to :product
  belongs_to :market_place
  belongs_to :variant
  belongs_to :seller

  default_scope where(:deleted_at => nil)

end
