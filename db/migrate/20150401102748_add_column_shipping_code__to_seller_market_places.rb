class AddColumnShippingCodeToSellerMarketPlaces < ActiveRecord::Migration
  def change
    add_column :spree_seller_market_places, :shipping_code, :string, :default=>"0"
  end
end
