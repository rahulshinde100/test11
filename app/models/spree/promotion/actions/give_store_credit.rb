module Spree
  class Promotion::Actions::GiveStoreCredit < PromotionAction
    preference :amount, :decimal, :default => 0.0
    preference :validity, :integer, :default => 0
    attr_accessible :preferred_amount, :preferred_validity

    def perform(options = {})
      if _user = options[:user]
        return if _user.store_credits.present? && _user.store_credits.promo.present?
        if preferred_validity > 0
      	  expires_at = (Time.now + preferred_validity.days).end_of_day      	
        else
          expires_at = nil
        end
        _user.store_credits.create(:amount => preferred_amount, :remaining_amount => preferred_amount,  :reason => "Promotion: #{promotion.name}", :expires_at => expires_at)        
      end      
    end
  end
end
