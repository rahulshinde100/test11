class AddComapnyToSpreeProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :company, :string
    add_column :spree_products, :website, :string
    add_column :spree_products, :url, :string
    add_column :spree_products, :is_new_arrival, :boolean, :default => false
    add_column :spree_products, :is_featured, :boolean, :default => false
  end
end
