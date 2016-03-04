Spree::Admin::StoreCreditsController.class_eval do
	# after_filter :send_email, :only => :create
	before_filter :expiry_date, :only => [:create, :update]

	def index
		if params[:sc] == 'promo'
			@store_credits = Spree::StoreCredit.promo
		elsif params[:sc] == 'manually'
			@store_credits = Spree::StoreCredit.manually
		elsif params[:sc] == "expired"
			@store_credits = Spree::StoreCredit.expired
		else
			@store_credits = Spree::StoreCredit.all
		end
		@store_credits = Kaminari.paginate_array(@store_credits).page(params[:page]).per(30)
	end
	def update_email_message
		if Spree::Config.has_preference? "store_credit_email_text"
			Spree::Config[:store_credit_email_text] = params[:store_credit_email_text]
			flash[:success] = Spree.t(:successfully_updated)
		else
			flash[:error] = "Error updating #{Spree.t(:store_credit_email_text)}"
		end
		if request.xhr?
			render :js => 'update_email_message'
		end
	end
	protected
	 def send_email
	 	user = @store_credit.user
	 	message = params[:store_credit_email_text] || Spree::Config[:store_credit_email_text]
	 	Spree::UserMailer.welcome(user, message).deliver if user.present?
	 end

	 def expiry_date	 	
	 	expires_at = params[:store_credit][:expires_at]
	 	if expires_at.present?
	 		if expires_at.to_date.end_of_day < Time.now
	 			params[:store_credit].merge!(:expires_at => expires_at.to_date.end_of_day, :remaining_amount => 0)
	 		else
	 			params[:store_credit].merge!(:expires_at => expires_at.to_date.end_of_day)
	 		end
	 	end
	 end
end