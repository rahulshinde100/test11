# This migration comes from spree_multi_seller (originally 20130627075647)
class CreateSpreeSellerCategories < ActiveRecord::Migration
	def self.up  
    create_table :spree_seller_categories do |t|  
      t.references :seller
      t.references :taxonomy  
      t.timestamps
    end  
    add_index :spree_seller_categories, [:seller_id, :taxonomy_id]  
    add_index :spree_seller_categories, [:taxonomy_id, :seller_id]  
  end  
  
  def self.down  
    drop_table :spree_seller_categories  
  end  
end