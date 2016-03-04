#require 'config/environments/de'

#Import data

#Rake::Task['db:seed'].enhance ['device_user']

desc "Importing Data and images, Please wait... "
task :import_data, :sku do |t|
  system( "bundle exec thor datashift:spree:products -i tmp/data_import/datashift/product_import_with_images.xls -s MLI" )
end

desc "Importing TEST data to OMS"
task :place_order => :environment do
  #where(payment_state => 'paid', :completed_at => !nil)
  Spree::Order.shipment_ready.each do |ord|
      puts "Placing orders to OMS, Please wait....."
      resp = RestClient.post(OMS_PATH, :api_key => OMS_API_KEY, :order_bucket => ord.get_order_bucket)
      puts "==========#{resp.inspect}"
      puts "----------------------------xx-----------------------------\n Order #{ord.number} is placed to MLI"
  end
end

# Task for adding the iPad user added by Vishal
task :device_user => :environment do
	user = Spree::User.create!(:first_name => "Apple", :last_name => "User", :email => "apple_user@mylifeinc.com", :password => "appleuser", :password_confirmation => "appleuser" )   
  user.roles << Spree::Role.find_by_name('user')
	user.generate_api_key!
  user.ensure_authentication_token!
	#puts "#{user.api_key} for device users"
end

