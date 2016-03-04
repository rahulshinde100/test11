class AddConfirmableToDeviseV1 < ActiveRecord::Migration
  def change
  	add_column :spree_users, :confirmation_token, :string, :unique => true 
  	add_column :spree_users, :confirmed_at, :datetime
  	add_column :spree_users, :confirmation_sent_at, :datetime
  	add_column :spree_users, :unconfirmed_email, :string
  end
end
