module Spree
	module Api
		class SellerUsersController < Spree::Api::BaseController

			def index
				@seller = current_api_user.seller
				@users =  @seller.users
				@users = @users.page(params[:page]).per(params[:per_page])
			end

			def create
				@seller = current_api_user.seller
				#raise current_api_user.inspect
				roles = params[:seller_roles]
		    	#raise params[:seller_roles].inspect
		    	if params[:exists] == 'true'
		    		@seller_user = @seller.seller_users.build({:user_id => Spree::User.find_by_email(params[:user][:email]).id})
		    		@seller_user.save
		    		@user = Spree::User.find(@seller_user.user_id)
		    		#@seller_user.save
		    	else
					@user = Spree::User.new(params[:user])
					#@user.save
					if @user.save
			    		@user.generate_spree_api_key! if @user.spree_api_key.blank?
						@user.reset_authentication_token!
			    		@seller.seller_users.build(:user_id => @user.id)
			    		@seller.save
			    		if !roles.blank?
			    			@user.spree_roles << roles.collect{|r| Spree::Role.find(r)}
			    		end
			    		Spree::SellerMailer.seller_user_welcome(@user).deliver
			    		#@user.spree_roles = roles.collect{|r| Spree::Role.find(r)} if !roles.blank?
			    	else
			    		@error = {:error => "Email already taken"}
			    	end
			    end
				
			end

			def edit
        		@seller = current_api_user.seller
				roles = params[:seller_roles]
			end

			def show
				@seller_user = Spree::SellerUser.find_by_user_id(params[:id])
				@user = @seller_user.user
			end

			def update
        		@seller = current_api_user.seller
				roles = params[:seller_roles]

				@seller_user = Spree::SellerUser.find_by_user_id(params[:id])
				#@seller_user = @seller.seller_users.find_by_user_id(params[:id])
				#raise params[:id].inspect
				
				if @seller_user
					if  @seller_user.user.update_attributes(params[:user])
						if !roles.blank?
		    				@seller_user.user.spree_roles.delete_all
		    				@seller_user.user.spree_roles << roles.collect{|r| Spree::Role.find(r)}
		    			end
					end
				else
					render :json => {:response => "record not found"}
				end


			end

			def destroy
				@seller_user = Spree::SellerUser.find_by_user_id(params[:id])
				@seller = current_api_user.seller
				#@seller_user = @seller.seller_users.find_by_user_id(params[:id])
				if @seller_user
					@seller_user.user.spree_roles.destroy_all
					@seller_user.destroy
	        		@response = {:response => "User deleted successfuly" }
	        	else
	        		@response = {:response => "Record not Found" }
	        	end

			end
		end
	end
end
      
