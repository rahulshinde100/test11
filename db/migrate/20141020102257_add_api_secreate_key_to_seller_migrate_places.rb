class AddApiSecreateKeyToSellerMigratePlaces < ActiveRecord::Migration
  def change
    add_column :spree_seller_market_places, :api_secret_key, :string
  end
end
