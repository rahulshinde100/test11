# This migration comes from spree_multi_seller (originally 20130812120341)
class AddColumnToSpreeStockLocations < ActiveRecord::Migration
  def change
    add_column :spree_stock_locations, :is_warehouse, :boolean, :default => false
  end
end
