class AddPermalinkToSeller < ActiveRecord::Migration
  def change
    add_column :spree_sellers, :permalink, :string
  end
end
