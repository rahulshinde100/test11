# This migration comes from spree_multi_seller (originally 20130705090949)
class AddColumnToSpreeSeller < ActiveRecord::Migration
  def change
    add_column :spree_sellers, :comment, :string
  end
end
