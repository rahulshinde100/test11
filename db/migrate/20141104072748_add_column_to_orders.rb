class AddColumnToOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :fulflmnt_state, :string , :default => nil
    add_column :spree_orders, :fulflmnt_tracking_no, :string , :default => nil
  end
end
