class AddColumnToSpreeStockLocations < ActiveRecord::Migration
  def change
    add_column :spree_stock_locations, :is_warehouse, :boolean, :default => false
  end
end
