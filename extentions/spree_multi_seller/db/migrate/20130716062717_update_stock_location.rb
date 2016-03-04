class UpdateStockLocation < ActiveRecord::Migration
  def change
    add_column :spree_stock_locations, :contact, :string
    add_column :spree_stock_locations, :email, :string,  :null => false
    add_column :spree_stock_locations, :web_url, :string
    add_column :spree_stock_locations, :operating_hours, :string
    add_column :spree_stock_locations, :pickup_at, :boolean, :default => false
    add_column :spree_stock_locations, :lat, :string
    add_column :spree_stock_locations, :lng, :string
    add_column :spree_stock_locations, :locname, :string
  end
end
