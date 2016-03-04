class Spree::StoreCreditObserver < ActiveRecord::Observer
  observe Spree::StoreCredit
  def after_create(store_credit)
  	user = store_credit.user
 	message = store_credit.try(:store_credit_email_text) || Spree::Config[:store_credit_email_text]
 	if store_credit.is_promo?
 		Spree::UserMailer.welcome(user, message).deliver if user.present?
 	else
 		Spree::UserMailer.store_credit(user, message).deliver if user.present?
 	end
  end
end
