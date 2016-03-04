class CreateKits < ActiveRecord::Migration
  def self.up
    create_table :spree_kits do |t|
      t.references :seller
      t.string :name
      t.string :sku
      t.string :description
      t.integer :quantity
      t.boolean :is_common_stock, :default => true
      t.boolean :is_active, :default => true
      t.timestamps
    end
    add_index :spree_kits, :seller_id
  end

  def self.down
    drop_table :spree_kits
  end
end
