Spree::Api::UsersController.class_eval do
  #before_filter :check_for_api_key, :except => [:sign_up,:sign_in, :social_sign_up, :social_sign_in,:logout]

  def sign_up
    @user = Spree::User.new(params[:user])
    if @user.save
      @user.update_attributes(:country_id => 160)
      @user.reset_authentication_token!
      @user.generate_spree_api_key! if @user.spree_api_key.blank?
    else
      invalid_resource!(@user)
    end
  end

  def sign_in

    @user = Spree::User.find_by_email(params[:user][:email])

    if @user.present?

      if params[:app_type] == "digitizer"
        if @user.has_spree_role?("seller") || @user.has_spree_role?("seller_store")
        if @user.seller.active?
          if !@user.present? || !@user.valid_password?(params[:user][:password])
              #unauthorized
              @error = {:error => "Please check the email and password again"}
              return
            else
              @user.register_for_apns_notifications(params[:user][:device_token]) #register iOS device
              @user.generate_spree_api_key! if @user.spree_api_key.blank?
              @user.reset_authentication_token!
            end
          else
            @error = {:error => "seller is not activated"}
            return
          end
        else
          @error = {:error => "You are not authorized to log in"}
          return
        end
      else

        if !@user.present? || !@user.valid_password?(params[:user][:password])
          #unauthorized
          @error = {:error => "Please check the email and password again"}
          return
        else
          @user.generate_spree_api_key! if @user.spree_api_key.blank?
          @user.reset_authentication_token!
        end
      end
    else
      @error = {:error => "User not found"}
    end
  end

  def register_device
    unless current_api_user
      @status = {:response => "Please sign in"}
      return
    end

    if current_api_user.register_for_apns_notifications(params[:device_token])
      @status = {:response => "Device Added"}
    else
      @status = {:response => "Device is not added successfully"}
    end

  end

  def social_sign_up
    user = Spree::User.find_by_email(params['user']['email'])
    auth = Spree::UserAuthentication.find_by_uid(params[:user][:user_authentication][:uid])
    if user && auth.nil?
      user.social_login(params[:user][:user_authentication])
    elsif user.nil?
      user = Spree::User.new
      user.apply_omniauth_api(params[:user])
    end
    if user.save
      @user = user
      @user.generate_spree_api_key! if @user.spree_api_key.blank?
      @user.reset_authentication_token!
    else
      invalid_resource!(@user)
    end
  end

  def forget_password
    if current_api_user.present?
      current_api_user.send_reset_password_instructions
      @status = {:response => "Reset password instructions sent to your email"}
    else
      @status = {:response => "Record not found"}
    end
  end

  def order_history
    if current_api_user.present?
      if current_api_user.orders.exists?
        @orders = current_api_user.orders.where("state = 'Complete'")
        @orders = @orders.page(params[:page]).per(params[:per_page])
      end
    end
  end

  def change_password
    @user = current_api_user
    if current_api_user.valid_password?(params[:passwords][:old_password])
      if @user.update_attributes(:password => params[:passwords][:new_password])
        @alert = {:response => "Success"}
      else
        @alert = {:response => "Failed"}
      end
    else
      @alert = {:response => "password do not match"}
    end

  end

  #allow multi user login on different devices
  def logout
    if current_api_user
      current_api_user.unregister_for_apns_notifications(params[:device_token])
      @status = {:response => "logout successfuly"}
    else
      @status = {:error => "Record not found"}
    end
  end
end
