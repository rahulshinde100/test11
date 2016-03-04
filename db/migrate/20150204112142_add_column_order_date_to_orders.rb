class AddColumnOrderDateToOrders < ActiveRecord::Migration
  def up
    add_column :spree_orders, :order_date, :datetime
    add_column :spree_orders, :last_updated_date, :datetime

    add_index :spree_orders, :order_date
    add_index :spree_orders, :last_updated_date
  end

  def down
    remove_index :spree_orders, :order_date
    remove_index :spree_orders, :last_updated_date
    remove_column :spree_orders, :order_date
    remove_column :spree_orders, :last_updated_date
  end
end
