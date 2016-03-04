class AddColumnShippingCarrierCodeToSellerMarketPlaces < ActiveRecord::Migration
  def change
    add_column :spree_seller_market_places, :shipping_carrier_code, :string, :default=>"FBA"
  end
end
