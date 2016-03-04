## app/controllers/api/base_controller_decorator.rb
#
Spree::Api::BaseController.class_eval do
  before_filter :set_user
  
  def set_user
    Spree::User.current_user = current_api_user
  end
  
  def verify_seller
    unless (@seller.users.map(&:id).include?(current_api_user.id) || current_api_user.has_spree_role?("admin"))
      raise CanCan::AccessDenied do |exception|
        redirect_to root_url, :alert => "You are not authorise to access this page"
      end
    end
  end

  def verify_seller_product
    unless (@product.seller.users.map(&:id).include?(spree_current_user.id) || spree_current_user.has_spree_role?("admin"))
      raise CanCan::AccessDenied do |exception|
        redirect_to root_url, :alert => "You are not authorise to access this page"
      end
    end
  end

  def load_stock_location
    @stock_location = Spree::StockLocation.find(params[:stock_location_id])
    user_stock_location = spree_current_user.seller.try(:stock_locations)
    user_stock_location = user_stock_location.nil? ? [] : user_stock_location.map(&:id)
    unless (user_stock_location.include?(@stock_location.id) || spree_current_user.has_spree_role?("admin"))
      raise CanCan::AccessDenied do |exception|
        redirect_to root_url, :alert => "You are not authorise to access this page"
      end
    end
  end

end