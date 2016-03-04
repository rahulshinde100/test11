class AddIsActiveIntoSellersMarketPlacesProducts < ActiveRecord::Migration
  def change
    add_column :spree_sellers_market_places_products, :is_active, :boolean, :null => false, :default=>true
    add_column :spree_price_managements, :is_active, :boolean, :null => false, :default=>true
    add_column :spree_title_managements, :is_active, :boolean, :null => false, :default=>true
    add_column :spree_description_managements, :is_active, :boolean, :null => false, :default=>true
    add_column :spree_sellers_market_places_products, :last_update_on_mp, :datetime, :null => false, :default => Time.zone.now
    add_column :spree_sellers_market_places_products, :unmap_mail_sent_at, :datetime
    add_index :spree_sellers_market_places_products, :is_active
    add_index :spree_price_managements, :is_active
    add_index :spree_title_managements, :is_active
    add_index :spree_description_managements, :is_active  
  end
end
