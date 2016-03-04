class CreateKitProducts < ActiveRecord::Migration
  def self.up
    create_table :spree_kit_products do |t|
      t.references :kit
      t.references :product
      t.integer :quantity
      t.timestamps
    end
    add_index :spree_kit_products, :kit_id
    add_index :spree_kit_products, :product_id
  end

  def self.down
    drop_table :spree_kit_products
  end
end
