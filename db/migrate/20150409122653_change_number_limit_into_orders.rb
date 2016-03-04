class ChangeNumberLimitIntoOrders < ActiveRecord::Migration
  def up
    change_column :spree_orders, :number, :string, :limit => 255
  end

  def down
    change_column :spree_orders, :number, :string, :limit => 15
  end
end
