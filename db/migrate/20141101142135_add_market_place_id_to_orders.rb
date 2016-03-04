class AddMarketPlaceIdToOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :market_place_id, :integer
    add_column :spree_orders, :market_place_order_no, :string
    add_column :spree_orders, :market_place_order_status, :string
    add_index :spree_orders, :market_place_id
    add_index :spree_orders, :market_place_order_no
  end
end
