class AddGenderToProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :gender, :string, default: 'NA'
  end
end
