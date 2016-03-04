module Spree
	class ProductNotificationsController < ApplicationController

		def notify_me
			if spree_current_user
				unless spree_current_user.notifications.exists?(:variant_id => params[:variant_id].to_i)
					@product_notification = spree_current_user.notifications.build(:variant_id => params[:variant_id]).save
          #add product to wishlist
          wishlist = Spree::WishedProduct.new(:variant_id => params[:variant_id], :wishlist_id => spree_current_user.wishlist.id)
          wishlist.save!

          flash[:success] = "You have successfully registerd for the service"
          if request.xhr?
	          render :text => "register"
	          return
      		end
				else
					flash[:success] = "You have already registerd for the service"
					if request.xhr?
	          render :text => "already_register"
						return
					end
				end
			 	 redirect_to request.referrer
			 	 return
      else
        render :text => "login"
			end
      return
		end
	end
end
