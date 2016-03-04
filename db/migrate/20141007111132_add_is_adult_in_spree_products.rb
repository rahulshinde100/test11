class AddIsAdultInSpreeProducts < ActiveRecord::Migration
  def up
    add_column :spree_products, :is_adult, :boolean, :default => false
  end

  def down
    remove_column :spree_products, :is_adult
  end
end
