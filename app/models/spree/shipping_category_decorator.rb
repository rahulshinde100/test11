Spree::ShippingCategory.class_eval do
	def self.general
		Spree::ShippingCategory.find_by_name("Delivered in 1 to 2 days")
	end

	def self.same_day_shipping
		Spree::ShippingCategory.find_by_name("Same Day Delivery")
	end
	
	def self.minutes99
		Spree::ShippingCategory.find_by_name("99 Minutes")
	end

	def is_same_day_shipping?
		self.name == "Same Day Delivery"                
	end
	def is_general?
		self.name == "Delivered in 1 to 2 days"
	end

	def is_99minute?
		self.name == "99 Minutes"
	end

end