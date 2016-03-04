# This migration comes from spree_multi_seller (originally 20130703073533)
class RemoveUserIdFromSpreeSeller < ActiveRecord::Migration
  def up
    remove_column :spree_sellers, :user_id
  end

  def down
    add_column :spree_sellers, :user_id, :integer
  end
end
