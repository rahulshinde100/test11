class AddColumnToSpreeSellerMarketPlaces < ActiveRecord::Migration
  def change
    add_column :spree_seller_market_places, :api_key,   :string
    add_column :spree_seller_market_places, :fba_api_key,  :string
    add_column :spree_seller_market_places, :country,  :string
    add_column :spree_seller_market_places, :currency_code,  :string
    add_column :spree_seller_market_places, :is_active, :boolean, :default => true
  end
end
