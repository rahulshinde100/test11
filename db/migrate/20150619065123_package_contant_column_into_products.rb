class PackageContantColumnIntoProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :package_content, :text
  end
end
