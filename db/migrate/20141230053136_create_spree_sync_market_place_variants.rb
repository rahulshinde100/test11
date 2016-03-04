class CreateSpreeSyncMarketPlaceVariants < ActiveRecord::Migration
  def self.up
    create_table :spree_sync_market_place_variants do |t|
      t.references :seller
      t.references :market_place
      t.references :product
      t.references :variant
      t.string :variant_sku
      t.timestamps
    end
    add_index :spree_sync_market_place_variants, :seller_id
    add_index :spree_sync_market_place_variants, :market_place_id
    add_index :spree_sync_market_place_variants, :product_id
    add_index :spree_sync_market_place_variants, :variant_id
  end

  def self.down
    drop_table :spree_sync_market_place_variants
  end
end
