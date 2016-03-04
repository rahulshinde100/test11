class CreateSpreeProductNotifications < ActiveRecord::Migration
  def change
    create_table :spree_product_notifications do |t|
      t.integer :user_id
      t.integer :variant_id

      t.timestamps
    end
  end
end
