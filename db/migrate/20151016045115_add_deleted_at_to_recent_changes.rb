class AddDeletedAtToRecentChanges < ActiveRecord::Migration
  def change
    add_column :spree_recent_market_place_changes, :deleted_at, :datetime, default:nil
  end
end
