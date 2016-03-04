class AddColumnToSpreeSellers < ActiveRecord::Migration
  def change
  	add_column :spree_sellers, :seller_user_ids, :string #csv
  end
end
