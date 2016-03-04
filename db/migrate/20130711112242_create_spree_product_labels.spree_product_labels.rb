# This migration comes from spree_product_labels (originally 20120726153121)
class CreateSpreeProductLabels < ActiveRecord::Migration
  def change
  	create_table :spree_product_labels, :force => true do |t|
      t.integer :product_id
      t.integer :label_id
      t.integer :position
    end
  end

end
