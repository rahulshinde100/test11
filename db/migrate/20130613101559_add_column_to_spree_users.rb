class AddColumnToSpreeUsers < ActiveRecord::Migration
  def change
  	add_column :spree_users, :firstname, :string
    add_column :spree_users, :lastname, :string
    add_column :spree_users, :dateofbirth, :date
    add_column :spree_users, :gender_id, :integer
    add_column :spree_users, :country_id, :integer
    add_column :spree_users, :contact, :string
  end
end
