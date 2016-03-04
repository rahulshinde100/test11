class AddColumnToUserAuthentications < ActiveRecord::Migration
  def change
  	add_column :spree_user_authentications, :photo, :string
  	add_column :spree_user_authentications, :location, :string
  end
end
