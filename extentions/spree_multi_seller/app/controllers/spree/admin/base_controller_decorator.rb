## app/controllers/admin/base_controller_decorator.rb
#
Spree::Admin::BaseController.class_eval do

  def breadcrumb_path(path)
    if spree_current_user.has_spree_role? 'seller'
      root_path = {:home => "/admin/sellers"}
    else      
      root_path = {:home => "/admin"}
    end
    path = {} if path.nil?
    path = root_path.merge!(path)
    links = []
    index = 0
    root_path.each do |title, link|
        if(index == root_path.length - 1)
          links << link.to_s.humanize
        else
          links << "<a href='#{link}' title='#{title}'>#{title.to_s.underscore.humanize}</a>"
        end

        index = index + 1
    end
    return links.join("&nbsp;&#187;&nbsp;")
  end

  def verify_seller
    unless (spree_current_user.has_spree_role?("admin") || @seller.users.map(&:id).include?(spree_current_user.id))
      raise CanCan::AccessDenied do |exception|
        redirect_to root_url, :alert => "You are not authorise to access this page"
      end
    end
  end

  def verify_seller_product
    unless (spree_current_user.has_spree_role?("admin") || @product.seller.users.map(&:id).include?(spree_current_user.id))
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

  def authorize_roles
    authorize! :admin, Object
    authorize! :retailer, Object
  end 

end