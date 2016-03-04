class AddIsCmUserIntoSellers < ActiveRecord::Migration
  def change
    add_column :spree_sellers, :is_cm_user, :boolean, default:true
  end
end
