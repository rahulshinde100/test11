class AddColumnMarketPlaceProductCode < ActiveRecord::Migration
  def change
    add_column :spree_sellers_market_places_products, :market_place_product_code,   :string
  end
end
