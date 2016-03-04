class AddPermalinkToSeller < ActiveRecord::Migration
  def change
    add_column :spree_seller, :permalink, :string
  end
end
