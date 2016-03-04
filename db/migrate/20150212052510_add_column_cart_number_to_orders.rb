class AddColumnCartNumberToOrders < ActiveRecord::Migration
  def up
    add_column :spree_orders, :cart_no, :string

    add_index :spree_orders, :cart_no
  end

  def down
    remove_index :spree_orders, :cart_no

    remove_column :spree_orders, :cart_no
  end
end
