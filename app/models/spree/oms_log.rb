class Spree::OmsLog < ActiveRecord::Base
   attr_accessible :order_id, :oms_reference_number, :oms_api_responce, :oms_api_message, :server_error_log
   belongs_to :order

   scope :pending, where("oms_api_responce is null or oms_api_responce != 'success'")

   scope :success, where(:oms_api_responce => "success")
end
