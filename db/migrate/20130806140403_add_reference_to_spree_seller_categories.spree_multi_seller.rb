# This migration comes from spree_multi_seller (originally 20130806140037)
class AddReferenceToSpreeSellerCategories < ActiveRecord::Migration
  def change
  	change_table :spree_seller_categories do |t|
	  	t.references :taxon
	  	t.remove :taxonomy_id
	  end
		add_index :spree_seller_categories, [:taxon_id, :seller_id]  
  end
end
