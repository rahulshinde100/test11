class AddSellerInLabel < ActiveRecord::Migration
  def up
    add_column :spree_labels, :seller_id, :integer
    add_column :spree_labels, :is_approved, :boolean, :default => false
  end

  def down
    remove_column :spree_labels, :seller_id
    remove_column :spree_labels, :is_approved
  end
end
