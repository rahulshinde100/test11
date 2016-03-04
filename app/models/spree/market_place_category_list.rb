class Spree::MarketPlaceCategoryList < ActiveRecord::Base
  require 'csv'
  attr_accessible :market_place_id, :category_code, :name
  	
  	# Added by Tejaswini Patil
  	# To read the category file
 	# Last modified 13/11/014
	def self.import(file, market_place)
	  message = ""
	  count = 0
	  begin
  	  File.foreach(file.path) do |row|
  	     if row.present? && count > 0
  	       val = row.gsub('"', '').gsub(/\;/, ',').gsub("\n", "").split(",")
  	       category = Spree::MarketPlaceCategoryList.where("category_code=? AND market_place_id=?",val[0], market_place)
  	       if category.present?
  	         category.first.update_attributes(:category_code => val[0],:name => val[1].gsub("/", "<<"))
  	       else
  	         category = create!(:category_code => val[0],:name => val[1].gsub("/", "<<"), :market_place_id => market_place)  
  	       end
  	     end
  	     count = count + 1
  	  end
  	rescue Exception => e
  	  message = e.message  
  	end     
  	return message.empty? ? "Categories Synced" : message
  end

end
