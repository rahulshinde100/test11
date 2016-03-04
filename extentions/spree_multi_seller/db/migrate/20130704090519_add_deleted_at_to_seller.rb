class AddDeletedAtToSeller < ActiveRecord::Migration
  def change
    add_column :spree_sellers, :deleted_at, :datetime
    add_column :spree_sellers, :deactivated_at, :datetime
  end
end
