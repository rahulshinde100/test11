require 'rest_client'
require 'base64'

class Spree::PaymentObserver < ActiveRecord::Observer
  observe Spree::Payment

  def after_save(payment)
    if payment.completed?
      begin
        #detuct amount
        ambassador_promo = Spree::Promotion.find_by_name("ambassador")
        if payment.order.adjustments.eligible.promotion.select{|p| p.originator.promotion == ambassador_promo.try(:actions).try(:first).promotion}.present?
          Mbsy::Balance.update(:deduct,{:email => "#{payment.order.email}", :amount => 10, :email_new_ambassador => 0})
          amb = Mbsy::Ambassador.find(:email => "#{payment.order.email}")
          Mbsy::Balance.update(:add,{:email => amb["referring_ambassador"]["email"], :amount => 5, :email_new_ambassador => 0}) unless amb["referring_ambassador"]["email"].blank?
        end        
        anthorization = Base64.encode64("#{USER}:#{PASSWORD}")
        resp = RestClient.post(OMS_PATH, {:api_key => OMS_API_KEY, :email => OMS_USER_EMAIL, :signature => OMS_USER_SIGNATURE, :order_bucket => payment.order.get_order_bucket}, {:Authorization => "Basic #{anthorization}"})
        resp = JSON.parse(resp)
        #track response from OMS
        create_oms_log(resp, payment.order)
      rescue Exception => e
        create_local_log(e, payment.order)
        #save info into local database with error message
        #place all these order in last
      end
    end
  end

  def create_oms_log(resp, ord)
    Spree::OmsLog.create!(:order_id => ord.id, :oms_reference_number => resp["reference_id"], :oms_api_responce => resp["responce"], :oms_api_message => resp["message"])
  end

  def create_local_log(e, ord)
    Spree::OmsLog.create!(:order_id => ord.id, :server_error_log => e.message)
  end
end