class AddBussinessNameSeller < ActiveRecord::Migration
  def up
    add_column :spree_sellers, :business_name, :string, :null => false
  end

  def down
    remove_column :spree_sellers, :business_name
  end
end
