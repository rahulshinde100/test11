module Spree
	HomeController.class_eval do
     respond_to :html
     skip_filter :ensure_authorization
     caches_action :load_products

    def index
      if spree_current_user.present?
        redirect_to spree.admin_products_path
      else
          redirect_to spree.login_path
      end
      return
    end

    def business
      @title = "Sell on Ship.li"
    end

    def load_products
      @searcher = build_searcher(params)
      @products = @searcher.retrieve_products
      render :partial => "/spree/shared/categories"
      return
    end

    def ambassadors
      @ambassador_promo = Spree::Promotion.find_by_name("ambassador")
      #redirect_to "/login" and return
      unless (spree_current_user.nil? || !TURN_ON_AMBASSADORS || @ambassador_promo.nil?)
        referral = Mbsy::Event.create({:email => spree_current_user.email, :email_new_ambassador => 0, :first_name => spree_current_user.firstname,:short_code => "mbsy", :campaign_uid =>  GA_CAMPAIGN_ID, :auto_create => 1})
        @url = referral["ambassador"]["campaign_links"].first["url"]
        @unique_referrals = referral["ambassador"]["unique_referrals"]
        @campaign_name = referral["ambassador"]["campaign_links"].first["campaign_name"]
        @campaign_description = referral["ambassador"]["campaign_links"].first["campaign_description"]
        @balance_money = referral["ambassador"]["balance_money"]
      end
    end

  end
end
