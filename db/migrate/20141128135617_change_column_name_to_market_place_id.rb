class ChangeColumnNameToMarketPlaceId < ActiveRecord::Migration
  def self.up
    rename_column :spree_market_place_category_lists, :market_palce_id, :market_place_id
  end

  def self.down
    rename_column :spree_market_place_category_lists, :market_place_id, :market_palce_id
  end
end
