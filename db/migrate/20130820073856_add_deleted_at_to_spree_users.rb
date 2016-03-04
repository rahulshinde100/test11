class AddDeletedAtToSpreeUsers < ActiveRecord::Migration
  def change
    add_column :spree_users, :deleted_at, :datetime
  end
end
