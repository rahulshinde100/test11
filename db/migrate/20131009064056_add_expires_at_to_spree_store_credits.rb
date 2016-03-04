class AddExpiresAtToSpreeStoreCredits < ActiveRecord::Migration
  def change
    add_column :spree_store_credits, :expires_at, :datetime
    add_column :spree_store_credits, :store_credit_email_text, :string
  end
end
