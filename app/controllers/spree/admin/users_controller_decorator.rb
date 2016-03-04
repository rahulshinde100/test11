Spree::Admin::UsersController.class_eval do
	load_and_authorize_resource :class => Spree::User
  
  # For this method seller ability will not work
  # collection method is getting called before index method by default.
  # Collection is protected method of users controller , its default method of Spree core.
  # for Spree core seller role is not defined and we can not override it. So for collection seller ability will not work
  # Therefor for index also ability will not work, have to collect products from logged in use fo rseller
  def index
    if params[:revoke_delete_user].present?
      @revoke_users = Spree::User.unscoped.where("deleted_at is not null").collect{|user| user if user.has_spree_role?('seller')}.compact
    end
    @beta_users = Spree::BetaUser.all if params[:beta_users].present?
    
    if spree_current_user.has_spree_role?('seller')
      @collection = @collection.includes(:seller_user).where("spree_seller_users.seller_id = #{spree_current_user.seller.id}")
    end
    respond_with(@collection.not_deleted) do |format|
      format.html
      format.json { render :json => json_data }
    end
  end

  def create
    if params[:user].present?
      roles = params[:user].delete("spree_role_ids")
    end
    @user = Spree::User.new(params[:user])
    if @user.save
      if roles
        @user.spree_roles = roles.reject(&:blank?).collect{|r| Spree::Role.find(r)}
      end

      # Added by Tejaswini
      # To create seller user on creation of user with seller log in
      if spree_current_user.has_spree_role?('seller')
        Spree::SellerUser.create!(:user_id => @user.id,:seller_id => spree_current_user.seller.id)
      end

      flash.now[:success] = Spree.t(:created_successfully)
      if params[:beta_users].present?
        Spree::UserMailer.welcome_beta_use(@user).deliver
        redirect_to admin_users_path(:beta_users => "true")
        return
      else
       redirect_to admin_users_path
      end
    else
      flash.now[:success] = Spree.t(:error)
      if params[:beta_users].present?
        redirect_to admin_users_path(:beta_users => "true")
        return
      else
        render :new
      end
    end
  end

  def update
    if params[:user]
      roles = params[:user].delete("spree_role_ids")
    end

    if @user.update_attributes(params[:user])
      if roles
        @user.spree_roles = roles.reject(&:blank?).collect{|r| Spree::Role.find(r)}
      end

      if params[:user][:password].present?
        # this logic needed b/c devise wants to log us out after password changes
        user = Spree::User.reset_password_by_token(params[:user])
      end
      flash.now[:success] = Spree.t(:account_updated)
      redirect_to admin_users_path
    else
      render :edit
    end
  end

  def destroy    
    @user = Spree::User.find(params[:id])    
    raise DestroyWithOrdersError if @user.orders.complete.present?
    @user.update_attributes(:deleted_at => Time.now) unless @user.orders.complete.present?
    # flash.now[:success] = Spree.t(:account_deleted)
    redirect_to admin_users_path
  end  

  def revoke
    @user = Spree::User.unscoped.find(params[:id])
    @user.update_attributes(:deleted_at => nil)
    redirect_to admin_users_path(:revoke_delete_user => true)
  end

  def show
    puts "==============1"
    @user = Spree::User.find(params[:id])
  end
  protected

        def collection
          return @collection if @collection.present?
          if request.xhr? && params[:q].present?
            #disabling proper nested include here due to rails 3.1 bug
            #@collection = User.includes(:bill_address => [:state, :country], :ship_address => [:state, :country]).
            @collection = Spree::User.not_deleted.includes(:bill_address, :ship_address)
                              .where("spree_users.email #{LIKE} :search
                                     OR (spree_addresses.firstname #{LIKE} :search AND spree_addresses.id = spree_users.bill_address_id)
                                     OR (spree_addresses.lastname  #{LIKE} :search AND spree_addresses.id = spree_users.bill_address_id)
                                     OR (spree_addresses.firstname #{LIKE} :search AND spree_addresses.id = spree_users.ship_address_id)
                                     OR (spree_addresses.lastname  #{LIKE} :search AND spree_addresses.id = spree_users.ship_address_id)",
                                    { :search => "#{params[:q].strip}%" })
                              .limit(params[:limit] || 100)
          else
            @search = Spree::User.not_deleted.registered.ransack(params[:q])
            @collection = @search.result.page(params[:page]).per(Spree::Config[:admin_products_per_page])
          end
        end
end