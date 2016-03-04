class AdditionalFieldsForInventoryManagment < ActiveRecord::Migration
  def up
    add_column :spree_stock_transfers, :received_date, :date
    add_column :spree_stock_transfers, :damaged_quantity, :integer
    add_column :spree_stock_transfers, :total_order_cost, :integer
    add_column :spree_stock_transfers, :received_by, :string
    add_column :spree_stock_transfers, :expiry_date, :date
    add_column :spree_stock_transfers, :delivery_order, :string
    add_column :spree_stock_transfers, :purchase_order, :string
    
    add_column :spree_stock_transfers, :delivery_order_scan_copy_file_name, :string
    add_column :spree_stock_transfers, :delivery_order_scan_copy_content_type, :string
    add_column :spree_stock_transfers, :delivery_order_scan_copy_file_size, :integer
    add_column :spree_stock_transfers, :delivery_order_scan_copy_updated_at, :datetime
  end

  def down
    remove_column :spree_stock_transfers, :received_date
    remove_column :spree_stock_transfers, :damaged_quantity
    remove_column :spree_stock_transfers, :total_order_cost
    remove_column :spree_stock_transfers, :received_by
    remove_column :spree_stock_transfers, :expiry_date
    remove_column :spree_stock_transfers, :delivery_order
    remove_column :spree_stock_transfers, :purchase_order

    remove_column :spree_stock_transfers, :delivery_order_scan_copy_file_name
    remove_column :spree_stock_transfers, :delivery_order_scan_copy_content_type
    remove_column :spree_stock_transfers, :delivery_order_scan_copy_file_size
    remove_column :spree_stock_transfers, :delivery_order_scan_copy_updated_at
  end
end
