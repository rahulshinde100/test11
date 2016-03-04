class CreateSpreeSearchTerms < ActiveRecord::Migration
  def change
    create_table :spree_search_terms do |t|
      t.integer :user_id
      t.string :search_term
      t.integer :result_count

      t.timestamps
    end
  end
end
