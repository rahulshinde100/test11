class CreateSpreeSellersMarketPlacesKits < ActiveRecord::Migration
  def self.up
    create_table :spree_sellers_market_places_kits do |t|
      t.references :seller
      t.references :market_place
      t.references :kit
      t.timestamps
    end
    add_index :spree_sellers_market_places_kits, :seller_id
    add_index :spree_sellers_market_places_kits, :market_place_id
    add_index :spree_sellers_market_places_kits, :kit_id
  end

  def self.down
    drop_table :spree_sellers_market_places_kits
  end
end
