Spree::StoreCredit.class_eval do
	attr_accessible :expires_at, :store_credit_email_text
  Spree::Config[:use_store_credit_minimum] = 0.01

  scope :expired, where("expires_at != '' and expires_at < ? ", Time.now)
  scope :promo, where("reason like ?", "promotion%")
  scope :manually, where("reason not like ?", "%promotion%")

  def is_promo?
  	self.reason.include?("Promotion")
  end
end