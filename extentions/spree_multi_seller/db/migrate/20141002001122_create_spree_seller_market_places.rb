class CreateSpreeSellerMarketPlaces < ActiveRecord::Migration
  def self.up
    create_table :spree_seller_market_places do |t|
      t.references :seller
      t.references :market_place
      t.timestamps
    end
    add_index :spree_seller_market_places, :seller_id
    add_index :spree_seller_market_places, :market_place_id
  end

  def self.down
    drop_table :spree_seller_market_places
  end
end
