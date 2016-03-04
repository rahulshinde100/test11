class Spree::SellerMailer < Spree::BaseMailer
	default from: "business@ship.li"
  def welcome(seller)
		@seller = seller
		@subject = "Welcome to Ship.li"
		mail(:to => seller.contact_person_email, :subject => @subject)
	end
	def activate(seller)
		@seller = seller
		@subject = "Acount Activation"
		mail(:to => seller.contact_person_email, :subject => @subject)
	end

	def deactivate(seller)
		@seller = seller
		@subject = "Acount is Deactivate"
		mail(:to => seller.contact_person_email, :subject => @subject)
	end

	def deleted(seller)
		@seller = seller
		@subject = "Acount is Deleted"
		mail(:to => seller.contact_person_email, :subject => @subject)
	end

	def seller_user_welcome(seller_user)
		@user = seller_user
		@subject = "Welcome to Ship.li!"
		mail(:to => @user.email, :subject => @subject)
	end

	def guest_sign_up(seller)
		@seller = seller
		@subject = "Enquiry From Retailer"
		mail(:to => ["vaibhav.dabhade@anchanto.com","shivanand.kokate@anchanto.com","abhimanyu.kashikar@anchanto.com"], :subject => @subject)
	end

end
