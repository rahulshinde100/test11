class SetCreatedOnFba < ActiveRecord::Migration
  def up
    Spree::Variant.update_all(:is_created_on_fba => true)
  end

  def down
    Spree::Variant.update_all(:is_created_on_fba => false)
  end
end
