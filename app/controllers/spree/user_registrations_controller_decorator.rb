require 'mbsy'

module Spree
  UserRegistrationsController.class_eval do  	
  	skip_before_filter :ensure_authorization
  	before_filter :add_pass, :only => :create
  	after_filter :clear_omniauth, :only => :create
  	after_filter :welcome, :only => :create
    after_filter :refferal_discount, :only => :create

	 	private
	  	def clear_omniauth
	    	session[:omniauth] = nil unless spree_current_user && spree_current_user.new_record?
	  	end

	  	def welcome
        if spree_current_user
          fire_event("spree.user.signup")
	  		  Spree::UserMailer.welcome(spree_current_user).deliver if spree_user_signed_in? && !spree_current_user.has_store_credit?
        end
	  	end

	  	def add_pass
	  		params[:spree_user].merge(:password_confirmation => params[:spree_user][:password])
	  	end

      def refferal_discount
        return if (!TURN_ON_AMBASSADORS || spree_current_user.nil?)
        begin
          ap Mbsy::Event.create({:email => spree_current_user.email,:email_new_ambassador => 0, :first_name => spree_current_user.firstname,:short_code => (params[:mbsy] || "mbsy"), :campaign_uid =>  GA_CAMPAIGN_ID, :auto_create => 1})
          if !params[:mbsy].blank? && params[:campaignid].to_i == GA_CAMPAIGN_ID
            ambassador = Mbsy::Event.create({:email => spree_current_user.email, :revenue => 5, :email_new_ambassador => 0, :campaign_uid => GA_CAMPAIGN_ID})
            Mbsy::Balance.update(:add,{:email => ambassador["ambassador"]["email"], :amount => 10, :email_new_ambassador => 0})
          end
        rescue  Exception => e
          Rails.logger.info "===============================================\n #{e.message}"
        end
      end
  end
end