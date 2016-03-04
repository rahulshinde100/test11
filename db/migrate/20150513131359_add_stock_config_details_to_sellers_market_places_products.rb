class AddStockConfigDetailsToSellersMarketPlacesProducts < ActiveRecord::Migration
  def change
    add_column :spree_sellers_market_places_products, :stock_config_details, :integer, :default=>0
  end
end
