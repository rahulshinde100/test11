class AddStockConfigTypeToProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :stock_config_type, :integer, :default=>0
  end
end
