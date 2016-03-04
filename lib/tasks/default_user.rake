# default user creation for device user by tejaswini
task :default_ipad_user => :environment do
	user = Spree::User.find_by_email('apple_user@ship.li')
	if user.nil?
		user = Spree::User.create!(:firstname => "Apple", :lastname => "User", :email => "apple_user@ship.li", :password => "appleuser", :password_confirmation => "appleuser",:gender_id => 1 )   
	  	user.spree_roles << Spree::Role.find_by_name('user')
		user.generate_spree_api_key!
	  	user.ensure_authentication_token!
	end
end