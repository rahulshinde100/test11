class AddKitIdInProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :kit_id, :integer
    add_index :spree_products, :kit_id
  end
end
