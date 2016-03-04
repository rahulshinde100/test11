module Spree
  ReviewsController.class_eval do
        def destroy
            @review = Spree::Review.find(params[:id])
            @review.destroy
            redirect_to :back
        end

         def create
            params[:review][:rating].sub!(/\s*[^0-9]*$/,'') unless params[:review][:rating].blank?

            @review = Spree::Review.new(params[:review])
            @review.product = @product
            @review.user = spree_current_user if spree_user_signed_in?
            @review.ip_address = request.remote_ip
            @review.locale = I18n.locale.to_s if Spree::Reviews::Config[:track_locale]

            authorize! :create, @review           

            if @review.save
                @review.update_attributes(:review => params[:reviews][:review]) unless params[:reviews][:review].blank?
                if params[:reviews][:review].blank?
                    @review.update_attributes(:approved => true)
                end  
              flash[:notice] = Spree.t('review_successfully_submitted')
              redirect_to (product_path(@product))
            else
              render :action => "new"
            end
          end

  end
end
    