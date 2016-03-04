# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Spree::Core::Engine.load_seed if defined?(Spree::Core)
Spree::Auth::Engine.load_seed if defined?(Spree::Auth)

genders = YAML::load(File.open("#{Rails.root}/db/seed_files/gender.yml"))
ActiveRecord::Base.connection.execute("TRUNCATE TABLE spree_genders")
Spree::Gender.create!(genders)


bussiness_types = YAML::load(File.open("#{Rails.root}/db/seed_files/business_types.yml"))
ActiveRecord::Base.connection.execute("TRUNCATE TABLE spree_business_types")
Spree::BusinessType.create!(bussiness_types)

FileUtils::mkdir_p File.join(Rails.root, "public", "system", "lazada_invoice")