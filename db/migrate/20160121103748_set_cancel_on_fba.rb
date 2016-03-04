class SetCancelOnFba < ActiveRecord::Migration
  def up
    Spree::Order.where(:fulflmnt_state == 'cancel').update_all(:cancel_on_fba => true)
  end

  def down
  end
end
