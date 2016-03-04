class CreateBlockReviews < ActiveRecord::Migration
  def change
    create_table :spree_block_reviews do |t|
      t.text :block_comment
      t.integer :review_id
      t.timestamps
    end
  end
end
