# Configure Spree Preferences
#
# Note: Initializing preferences available within the Admin will overwrite any changes that were made through the user interface when you restart.
#       If you would like users to be able to update a setting with the Admin it should NOT be set here.
#
# In order to initialize a setting do:
# config.setting_name = 'new value'
Spree::AppConfiguration.class_eval do
  preference :facebook_app_id, :string
end

Spree.config do |config|
  # Example:
  # Uncomment to override the default site name.
  config.site_name = "Channel Manager"
  config.allow_ssl_in_production = false
  #facebook key
  config.facebook_app_id = "455274101188277"
  config.allow_ssl_in_staging = false
end
#mail method setting
Spree::Config[:enable_mail_delivery] = true
Spree::Config[:mail_domain] = "mandrillapp.com"


Spree.user_class = "Spree::User"
Spree::Config[:allow_guest_checkout] = false
#For paypal express checkout
Spree::Config[:auto_capture] = true
Spree::Config[:currency] = "SGD"
Spree::Config[:logo] = "admin/logo.png"
Spree::Config[:default_country_id] = Spree::Country.find_by_name("Singapore").id rescue nil
# Spree::Config[:site_url] = "http://ec2-54-251-110-203.ap-southeast-1.compute.amazonaws.com:3000"

#AWS Settings
if Rails.env.production?
  Spree.config do |config|
    #AWS settings
    config.use_s3 = true
    config.s3_bucket = 'shipliprod'
    config.s3_access_key = "AKIAJOVFXJNCJXXKFIQA"
    config.s3_secret = "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"
    config.attachment_url = ":s3_eu_url"
    config.s3_host_alias = "s3-ap-southeast-1.amazonaws.com"
    #paypal express checkout
    #config.site_url = Rails.env.production? ? 'https://www.ship.li' : 'http://stg.ship.li'
  end
else
  #Spree::Config[:site_url] = 'http://stg.ship.li:3000'
  Spree.config do |config|
    #AWS settings
    config.use_s3 = true
    config.s3_bucket = 'shipli'
    config.s3_access_key = "AKIAJOVFXJNCJXXKFIQA"
    config.s3_secret = "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"
    config.attachment_url = ":s3_eu_url"
    config.s3_host_alias = "s3.amazonaws.com"
  end
end

WickedPdf.config = {
  :exe_path => "#{Rails.root.to_s}/wkhtmltopdf"
}

#Get Ambassadors settings
TURN_ON_AMBASSADORS = true
SANDBOX_MODE = 1

GA_USERNAME = "anchanto"
GA_API_KEY = "c66f9d938153a5048301241c5eab19c5"

if SANDBOX_MODE == 1
  GA_CAMPAIGN_ID = 2145
  FB_APP_KEY = "455274101188277"
else #Production
  GA_CAMPAIGN_ID = 1985
  FB_APP_KEY = "256759424465398"
end
Mbsy.configure do |c|
    c.api_key = GA_API_KEY
    c.user_name = GA_USERNAME
end

Spree::Ability.register_ability(Spree::AbilityDecorator)
# Rails.application.config.spree.promotions.rules << Spree::Promotion::Rules::Seller
# Rails.application.config.spree.promotions.rules << Spree::Promotion::Rules::ItemCount
# Rails.application.config.spree.promotions.rules << Spree::Promotion::Rules::MarketPlace
# Rails.application.config.spree.promotions.rules << Spree::Promotion::Rules::Variant
# Rails.application.config.spree.promotions.rules << Spree::Promotion::Rules::Taxon
# Rails.application.config.spree.promotions.actions << Spree::Promotion::Actions::Discount

Rails.application.config.after_initialize do
  Rails.application.config.spree.promotions.rules = [Spree::Promotion::Rules::Seller,Spree::Promotion::Rules::ItemCount,Spree::Promotion::Rules::MarketPlace,Spree::Promotion::Rules::Variant,Spree::Promotion::Rules::Taxon,Spree::Promotion::Rules::ItemTotal]
  Rails.application.config.spree.promotions.actions = [ Spree::Promotion::Actions::Discount, Spree::Promotion::Actions::CreateLineItems ]
end
#SpreeEditor::Config.tap do |config|
#   config.ids = "product_description page_body event_body"
#end
