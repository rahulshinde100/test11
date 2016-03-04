# This migration comes from spree_multi_seller (originally 20130702141921)
class CreateSpreeSellerUsers < ActiveRecord::Migration
	def self.up  
    create_table :spree_seller_users do |t|  
      t.references :seller
      t.references :user  
      t.timestamps
    end  
    add_index :spree_seller_users, [:seller_id, :user_id]  
    add_index :spree_seller_users, [:user_id, :seller_id]  
  end  
  
  def self.down  
    drop_table :spree_seller_users  
  end  
end