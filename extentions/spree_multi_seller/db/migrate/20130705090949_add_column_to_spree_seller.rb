class AddColumnToSpreeSeller < ActiveRecord::Migration
  def change
    add_column :spree_sellers, :comment, :string
  end
end
