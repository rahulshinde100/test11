class AddColumnFbaSignatureToSellerMarketPlace < ActiveRecord::Migration
  def change
    add_column :spree_seller_market_places, :fba_signature, :text
  end
end
