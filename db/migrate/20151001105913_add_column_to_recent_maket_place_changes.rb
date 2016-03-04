class AddColumnToRecentMaketPlaceChanges < ActiveRecord::Migration
  def change
    add_column :spree_recent_market_place_changes, :update_on_fba, :boolean, default:false
  end
end
