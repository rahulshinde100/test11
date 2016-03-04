module Spree
	UserSessionsController.class_eval do 
		def create
	    authenticate_spree_user!
	    if spree_user_signed_in?
	      respond_to do |format|
	        format.html {
	          flash[:success] = Spree.t(:logged_in_succesfully)
	          if spree_current_user.has_spree_role? 'seller'
	          	redirect_to admin_orders_path
	          else
	          	redirect_back_or_default(after_sign_in_path_for(spree_current_user))
	          end
	        }
	        format.js {
	          user = resource.record
	          render :json => {:ship_address => user.ship_address, :bill_address => user.bill_address}.to_json
	        }
	      end
	    else
	      flash.now[:error] = t('devise.failure.invalid')
	      render :new
	    end
	  end
  end
end