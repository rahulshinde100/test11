class AddStockConfigTypeToSeller < ActiveRecord::Migration
  def change
    add_column :spree_sellers, :stock_config_type, :integer, :default=>1
  end
end
