class CreateSpreeSellersMarketPlacesProducts < ActiveRecord::Migration
  def self.up
    create_table :spree_sellers_market_places_products do |t|
      t.references :seller
      t.references :market_place
      t.references :product
      t.timestamps
    end
    add_index :spree_sellers_market_places_products, :seller_id
    add_index :spree_sellers_market_places_products, :market_place_id
    add_index :spree_sellers_market_places_products, :product_id
  end

  def self.down
    drop_table :spree_sellers_market_places_products
  end
end
