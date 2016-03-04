class AddWarehouseSaleInSpreeProducts < ActiveRecord::Migration
  def up
  	add_column :spree_products, :is_warehouse, :boolean, :default => false
  end

  def down
  	add_column :spree_products, :is_warehouse
  end
end
