class AddColumnIsCancelToOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :market_place_details, :text
    add_column :spree_orders,  :is_cancel, :boolean, :default=>false
  end
end
