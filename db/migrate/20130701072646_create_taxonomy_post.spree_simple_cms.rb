# This migration comes from spree_simple_cms (originally 20130312143916)
class CreateTaxonomyPost < ActiveRecord::Migration
  def change
    create_table :spree_taxonomy_posts do |t|
      t.string :name
      t.integer :position
      
      t.timestamps
    end
  end
end
