module Spree
  class SellerMarketPlace < ActiveRecord::Base
    attr_accessible :seller_id, :market_place_id, :api_key, :fba_api_key, :country, :currency_code, :is_active, :api_secret_key, :contact_name, :contact_number, :contact_email, :fba_signature, :shipping_code, :stock_config_details, :shipping_carrier_code

    belongs_to :market_place
    belongs_to :seller

    validates_presence_of :market_place_id, :seller_id, :fba_signature, :fba_api_key, :api_key, :shipping_carrier_code
  end
end
