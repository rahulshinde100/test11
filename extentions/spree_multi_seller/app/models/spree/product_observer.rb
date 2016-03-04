class Spree::ProductObserver < ActiveRecord::Observer
	observe Spree::Product

	def after_reject
		#Spree::ProductMailer.reject(product).deliver
	end
end
