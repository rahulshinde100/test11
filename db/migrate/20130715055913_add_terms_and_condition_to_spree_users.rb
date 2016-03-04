class AddTermsAndConditionToSpreeUsers < ActiveRecord::Migration
  def change
    add_column :spree_users, :terms_and_condition, :boolean, :default => false
  end
end
