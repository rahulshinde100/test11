module Spree
	module Admin
		class SellerUsersController < Spree::Admin::ResourceController
			load_and_authorize_resource :class => Spree::SellerUser
      		before_filter :load_seller, :verify_seller

			def index
				@seller_users = @seller.seller_users
			end

			def show
				@seller_user = @seller.users.find(params[:id])
				render :json => @seller_users.to_json
				return
			end

			def new
				@render_breadcrumb = breadcrumb_path({@seller.name => admin_seller_path(@seller.id), :disable => "Add User"})
				@seller_user = @seller.users.build
				@roles = Spree::Role.seller_roles
			end

			def create
				roles = params[:user].delete("spree_role_ids") if params[:user]
				if params[:exists] == 'true' && params[:email].present?
			        @got_user = Spree::User.where(:email => params[:email], :deleted_at => nil).first
			        if @got_user.present?
				     @user = @seller.seller_users.build({:user_id => @got_user.id})
				  else
                              flash[:error] = "Ooops!! User not found, please enter valid user"
					redirect_to new_admin_seller_seller_user_path(@seller, :exists => true)
					return
				  end
				else
				  @user = Spree::User.new(params[:user])
				end
				if @user.save
				   if params[:exists] == 'true'
				     @user.user.spree_roles = roles.reject(&:blank?).collect{|r| Spree::Role.find(r)} if roles
				   else
				     @seller.seller_users.build({:user_id => @user.id}).save!
				     @user.spree_roles = roles.reject(&:blank?).collect{|r| Spree::Role.find(r)} if roles
			         end
					flash[:success] = "Seller users added successfully !"
					redirect_to admin_seller_seller_users_path(@seller)
				else
			         @roles = Spree::Role.seller_roles
				   @seller_user = @user
				    render :new
				end
			end

			def edit
				@roles = Spree::Role.seller_roles
			end

			def update
				roles = params[:user].delete("spree_role_ids") if params[:user]
				if @seller_user.user.update_attributes(params[:user])
					@seller_user.user.spree_roles = roles.reject(&:blank?).collect{|r| Spree::Role.find(r)} if roles
					unless @seller_user.user.has_spree_role?("seller") || @seller_user.user.has_spree_role?("seller_store") || @seller_user.user.has_spree_role?("admin")
						     @seller_user.destroy
					end
					flash[:success] = "Seller users updated successfully !"
					redirect_to admin_seller_seller_users_path(@seller)
				else
					render :edit
				end
			end

			def select
				@users = params[:term].blank? ? [] : Spree::User.registered.where('lower(email) LIKE ?', "%#{params[:term].mb_chars.downcase}%")
				@users = @users.where(:deleted_at => nil)
				@users.delete_if { |user| user.seller.present? }
				render :json => @users.collect(&:email).to_json
			end

			def destroy
				@seller_user.destroy
				@seller_user.user.spree_roles.destroy_all
				redirect_to admin_seller_seller_users_path(@seller), :notice => "User deleted Successfully"
			end

			private
			def load_seller
				puts "================================#{params[:seller_id]}"
				@seller = Spree::Seller.find_by_permalink(params[:seller_id])
				puts "---------------------------------"
			end
		end
	end
end



