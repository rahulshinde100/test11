class AddOrderCanceledDateIntoOrders < ActiveRecord::Migration
  def up
    add_column :spree_orders, :order_canceled_date, :datetime
  end

  def down
    remove_column :spree_orders, :order_canceled_date
  end
end
