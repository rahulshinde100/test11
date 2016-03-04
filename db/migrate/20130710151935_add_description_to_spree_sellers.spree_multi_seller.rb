# This migration comes from spree_multi_seller (originally 20130710124553)
class AddDescriptionToSpreeSellers < ActiveRecord::Migration
  def change
    add_column :spree_sellers, :description, :text
  end
end
