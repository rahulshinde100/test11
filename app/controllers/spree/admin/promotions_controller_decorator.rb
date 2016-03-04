Spree::Admin::PromotionsController.class_eval do
	before_filter :update_params, :only => [:create, :update]
  before_filter :check_rules_and_type, :only => [:update]


  def index
    @promotions = Spree::Promotion.order('created_at desc')
    page = params[:page] || 0
    # @promotions = @promotions.page params[:page]
    @promotions = Kaminari.paginate_array(@promotions).page(params[:page]).per(15)
  end

  def force_close
    if @promotion.update_attributes(:expires_at => Time.zone.now)
      flash[:success] = 'Promotion has closed successfully'
    else
      flash[:error] = @order.errors[:base].join("\n")
    end

    redirect_to edit_admin_promotion_path(@promotion) and return
  end

	protected
		def update_params
      if params[:promotion].present?
        starts_at = params[:promotion][:starts_at]
        params[:promotion].merge!(:starts_at => starts_at.to_date.beginning_of_day) if starts_at.present?
        expires_at = params[:promotion][:expires_at]
        params[:promotion].merge!(:expires_at => expires_at.to_date.end_of_day) if expires_at.present?
        # if (starts_at.present?  && expires_at.present?) && (starts_at > expires_at)
        #   redirect_to edit_admin_promotion_path(@promotion), notice: "Start Date should not be greater than End date ." if params[:action] == 'update'
        #   redirect_to new_admin_promotion_path(@promotion), notice: "Start Date should not be greater than End date ." if params[:action] == 'create'
        #   return
        # end
       end
    end
  def check_rules_and_type
    p @promotion
    if (params[:promotion].present? && params[:promotion][:event_name].present?)
      if params[:promotion][:event_name] != 'spree.set_special_price'
        rules = @promotion.promotion_rules.where(:type => 'Spree::Promotion::Rules::Variant')
        if rules.present?
          @promotion.variants.each do |variant|
            if variant.parent_id.present? || variant.product.kit.present?
              redirect_to edit_admin_promotion_path(@promotion), notice: "Can not give Kit/Family as free product. Please remove kit/Family first to change promotion type."
            end
          end
        end
      end

     # elsif params[:promotion][:promotion_rules_attributes].present?
     #   if event_name != 'spree.set_special_price'
     #
     #   end
    end
  end
end
