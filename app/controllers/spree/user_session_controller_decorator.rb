module Spree
  UserSessionsController.class_eval do
  	skip_before_filter :ensure_authorization, :only => :create
  	def new
      @refer = Mbsy::Shortcode.find({ :short_code => params[:mbsy], :sandbox => SANDBOX_MODE }) unless params[:mbsy].blank?
			session[:login_type] ||= params[:login_type] unless params[:login_type].blank?
			session[:var_id] ||= params[:var_id] unless params[:var_id].blank?
			if request.xhr?
				respond_to do |format|
					format.html {render :layout => false}
				end
			else
				render :layout => true
			end
		end

		def create
	    authenticate_spree_user!
	    if spree_user_signed_in?
	    	#spree_current_user.update_store_credits if spree_current_user.has_store_credit?
	    	if session[:login_type] == 'wished_product'
		    	redirect_to add_to_wishlist_path(:variant_id => session[:var_id])
	    	 	return
    		elsif session[:login_type] == 'notify_me'
    			redirect_to product_notify_me_path(:variant_id => session[:var_id])
	    	 	return
    		else
		      #respond_to do |format|
		        #format.html {
		          flash[:success] = Spree.t(:logged_in_succesfully)
		          if spree_current_user.has_spree_role? 'seller'
		          	redirect_to admin_orders_path
		          else
		          	if params[:index].present?
	                  redirect_to root_url(:subdomain => false)
    	          else
                  if params[:return_path].present?
                    redirect_to params[:return_path]
                  else
                    redirect_to admin_orders_path
                    #redirect_back_or_default(after_sign_in_path_for(spree_current_user))
                  end
		    	    	end
		    	    end
		        #}
		        #format.js {
		          #user = resource.record
		          #render :json => {:ship_address => user.ship_address, :bill_address => user.bill_address}.to_json
		        #}
		      #end
		    end
	    else
	      flash.now[:error] = t('devise.failure.invalid')
	      if request.xhr?
	    		respond_to do |format|
	          format.js { render "error"}
	        end
	      else
        	if params[:index].present?
        		redirect_to root_url(:subdomain => false)
	    		else
		    		render :new
	    		end
	    	end
	  	end
		end
	end
end
