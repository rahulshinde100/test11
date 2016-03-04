class AddIndexesToOrders < ActiveRecord::Migration
  def up
    add_index :spree_orders, [:seller_id, :market_place_order_no], :unique => true
  end

  def down
    remove_index :spree_orders, [:seller_id, :market_place_order_no]
  end
end
