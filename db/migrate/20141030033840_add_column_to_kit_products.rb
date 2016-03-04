class AddColumnToKitProducts < ActiveRecord::Migration
  def change
    add_column :spree_kit_products, :variant_id, :integer
    add_index :spree_kit_products, :variant_id
  end
end
