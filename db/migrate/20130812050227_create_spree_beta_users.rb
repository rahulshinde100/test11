class CreateSpreeBetaUsers < ActiveRecord::Migration
  def change
    create_table :spree_beta_users do |t|
      t.string :email

      t.timestamps
    end
  end
end
