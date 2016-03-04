class AddColumnToSpreeProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :is_reject, :boolean, :default => false
  end
end
