class CreateSpreeGenders < ActiveRecord::Migration
  def change
    create_table :spree_genders do |t|
      t.string :name
      t.integer :position

      t.timestamps
    end
  end
end
