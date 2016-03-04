Rake::Task['db:seed'].enhance ['seller:create_roles']
# Seller Setup
namespace :seller do
  #=====================================
  desc "Seller Setup"
  task :create_roles => :environment do
    if Spree::Role.find_by_name("seller").blank?
      Spree::Role.create(:name => "seller")
    end
    if Spree::Role.find_by_name("seller_store").blank?
      Spree::Role.create(:name => "seller_store")
    end

    puts "seller roles are created"
  end
end