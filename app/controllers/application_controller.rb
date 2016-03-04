class ApplicationController < ActionController::Base
	before_filter :ensure_authorization
	skip_before_filter :verify_authenticity_token
  protect_from_forgery
  def self.current=(user)
   Thread.current[:user] = user
  end

  def ensure_authorization
    if Spree::Config[:login_necessity]
			unless spree_current_user
      			redirect_to root_url(:subdomain => false)
     		return
    	end
    	return
    end
    return
  end

  private
    def check_layout
      subdomain = request.subdomain.split(".")
      # if Rails.env.production?
         @seller = Spree::Seller.is_active.find_by_permalink(subdomain[0]) if subdomain[0].present?
      # else
      #   @seller = Spree::Seller.is_active.find_by_permalink(params[:permalink])
      # # end
      if @seller.present?
        'spree/layouts/retailer'
      else
        'spree/layouts/spree_application'
      end
    end
end
