module Spree
  UsersController.class_eval do
  	before_filter :fix_spree_user_var, :if => Proc.new {|p| p.spree_current_user.present?}
  	# before_filter :ensure_authorization
		def fix_spree_user_var
  		@spree_user = spree_current_user
		end

    def refer_to_friends
      
    end


    def show
    	@orders = @user.orders.complete.order('completed_at desc')    	
    	@message = "Your ship.li account carry $#{@user.try(:store_credits_total)} store credit.<br/>Please order to avail the credits before it expires."
      
      @ambassador_promo = Spree::Promotion.find_by_name("ambassador")
      referral = Mbsy::Ambassador.find(:email => spree_current_user.email)
      @url = referral["ambassador"]["campaign_links"].first["url"]
      @unique_referrals = referral["ambassador"]["unique_referrals"]
      @balance_money = referral["ambassador"]["balance_money"]
    end
  end
end
