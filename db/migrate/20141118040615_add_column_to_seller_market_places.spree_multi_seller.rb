# This migration comes from spree_multi_seller (originally 20141118040615)
class AddColumnToSellerMarketPlaces < ActiveRecord::Migration
  def change
    add_column :spree_seller_market_places, :contact_name,   :string
    add_column :spree_seller_market_places, :contact_number,  :string
    add_column :spree_seller_market_places, :contact_email,  :string
  end
end
