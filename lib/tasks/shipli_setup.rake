# Seller Setup
namespace :seller do
  #=====================================
  desc "Seller Setup"
  task :setup => :environment do
    genders = YAML::load(File.open("#{Rails.root}/db/seed_files/gender.yml"))
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE spree_genders")
    Spree::Gender.create!(genders)

    bussiness_types = YAML::load(File.open("#{Rails.root}/db/seed_files/business_types.yml"))
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE spree_business_types")
    Spree::BusinessType.create!(bussiness_types)
  end
  
  desc "Creating Seller..."
  task :create => :environment do
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE spree_sellers")
    puts "Creating a fake seller...."
    seller = Spree::Seller.create!({"name"=>"Addidas",
       "address_1"=>"Addidas,112,Bussiness House",
       "address_2"=>"Main Street",
       "city"=>"Singapore",
       "state"=>"Singapore",
       "country_id"=>"160",
       "zip"=>"12345",
       "contact_person_name"=>"Smith John",
       "contact_person_email"=>"smith.john@addidasfake.com",
       "phone"=>"9000123456",
       "roc_number"=>"12345",
       "paypal_account_email"=>"smith.john@addidasfake.com",
       "business_type_id"=>"1",
       "termsandconditions"=>"1",
       "is_active" => true,
       "establishment_date"=>Time.now})

   puts "Done!\n\n------------------\nCreating Shops"
   
   ActiveRecord::Base.connection.execute("TRUNCATE TABLE spree_store_addresses")
   store_address = seller.stores.build({"name"=>"City Addidas",
         "address"=>"123 Okhlahoma market,\r\nCity Road",
         "city"=>"Singapore",
         "state"=>"Singapore",
         "country_id"=>"160",
         "zipcode"=>"535354",
         "contact"=>"9000012345",
         "email"=>"city.addidas@addidasfake.com",
         "web_url"=>"http://www.cityaddidas.com",
         "operating_hours"=>"8 to 9",
         "pickup_at"=>"1"})
   store_address.save!

   puts "Done!\n\n------------------\nCreating Bank Details"
   ActiveRecord::Base.connection.execute("TRUNCATE TABLE spree_bank_details")
	 seller_bank_detail = seller.build_bank_detail({"name"=>"RBC",
       "branch"=>"city",
       "account_number"=>"[FILTERED]",
       "ifsc_code"=>"4321",
       "address"=>"RBC,City Branch,Main Market,\r\nSingapore"})
   seller_bank_detail.save!


   puts "Done!\n\n------------------\nCreating Seller User"
   user = Spree::User.find_by_email("admin@addidasfake.com")
   if user.nil?
      user = Spree::User.new({"email"=>"admin@addidasfake.com",
          "password"=>"addidas123",
          "password_confirmation"=>"addidas123"})
      user.save!
      user.spree_roles << Spree::Role.find_by_name("seller")
      seller.update_attributes({:user_id => user.id})
      puts "email------#{user.email}\npassword------addidas123"
   else
     puts "user already exist..."
   end

    puts "Done!\n\n------------------\nAssigning Seller Categories"
    Spree::SellerCategory.create!([{:taxonomy_id => "1", :seller_id => seller.id},{:taxonomy_id => "2", :seller_id => seller.id},{:taxonomy_id => "3", :seller_id => seller.id},{:taxonomy_id => "4", :seller_id => seller.id}])

    puts "Done!\n\n------------------\nCreating Products for the #{seller.name}"
    Spree::Product.all.each do |product|
      product.update_attributes({:seller_id => seller.id,:created_by => 1,:updated_by => 1,:is_approved => true}) if product.seller_id.nil?
    end

    puts "-------------FINISH--------------"
  end
end