class AddSellerIdToOrders < ActiveRecord::Migration
  def up
    add_column :spree_orders, :seller_id, :integer
    add_index :spree_orders, :seller_id
  end

  def down
    remove_index :spree_orders, :seller_id
    remove_column :spree_orders, :seller_id
  end
end
