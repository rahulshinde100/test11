class AddStockConfigDetailsToSellerMarketPlaces < ActiveRecord::Migration
  def change
    add_column :spree_seller_market_places, :stock_config_details, :integer, :default=>0
  end
end
