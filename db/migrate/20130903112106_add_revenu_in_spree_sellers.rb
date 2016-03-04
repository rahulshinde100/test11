class AddRevenuInSpreeSellers < ActiveRecord::Migration
  def up
    add_column :spree_sellers, :revenue_share, :decimal, :precision => 8, :scale => 2, :default => 0.0, :null => false
    add_column :spree_sellers, :revenue_share_on_ware_house_sale, :decimal, :precision => 8, :scale => 2, :default => 0.0, :null => false
  end

  def down
    remove_column :spree_sellers, :revenue_share
    remove_column :spree_sellers, :revenue_share_on_ware_house_sale
  end
end
