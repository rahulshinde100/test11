class CreateSpreeStockProducts < ActiveRecord::Migration
  def self.up
    create_table :spree_stock_products do |t|
      t.references :sellers_market_places_product
      t.references :variant
      t.integer :count_on_hand
      t.boolean :virtual_out_of_stock, :default => false
      t.timestamps
    end
    add_index :spree_stock_products, :sellers_market_places_product_id
    add_index :spree_stock_products, :variant_id
  end

  def self.down
    drop_table :spree_stock_products
  end
end
