# Added By Tejaswini Patil
# To add short name col to Spree::Product
class AddShortNameToProduct < ActiveRecord::Migration
  def up
    add_column :spree_products, :short_name, :string
  end

  def down
    remove_column :spree_products, :short_name
  end
end
