# This migration comes from spree_multi_seller (originally 20130702142948)
class AddColumnToSpreeSellers < ActiveRecord::Migration
  def change
  	add_column :spree_sellers, :seller_user_ids, :string #csv
  end
end
