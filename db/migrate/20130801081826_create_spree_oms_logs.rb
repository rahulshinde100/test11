class CreateSpreeOmsLogs < ActiveRecord::Migration
  def change
    create_table :spree_oms_logs do |t|
      t.integer :order_id, :null => false
      t.string  :oms_reference_number # A hash unique id, generated by OMS
      t.string  :oms_api_responce     # Response failure, success etc from OMS
      t.string  :oms_api_message      # Response message from OMS
      t.text    :server_error_log     # Local server log
      t.timestamps
    end
  end
end