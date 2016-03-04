class AddDescriptionToSpreeSellers < ActiveRecord::Migration
  def change
    add_column :spree_sellers, :description, :text
  end
end
