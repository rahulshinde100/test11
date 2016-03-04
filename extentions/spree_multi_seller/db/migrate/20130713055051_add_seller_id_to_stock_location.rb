class AddSellerIdToStockLocation < ActiveRecord::Migration
  def change
    add_column :spree_stock_locations, :seller_id, :integer
    add_column :spree_stock_transfers, :seller_id, :integer
  end
end
