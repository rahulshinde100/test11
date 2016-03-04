class AddIsBypassIntoOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :is_bypass, :boolean, :null => false, :default=>false
    add_index :spree_orders, :is_bypass 
  end  
end
