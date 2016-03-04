Spree::Api::VariantsController.class_eval do

  private
  def scope
    if @product
      unless current_api_user.has_spree_role?("admin") || params[:show_deleted]
        variants = @product.variants_including_master
      else
        variants = @product.variants_including_master.with_deleted
      end
    else
      current_api_user = defined?(spree_current_user) ? spree_current_user : current_api_user
      if current_api_user.has_spree_role?("admin")
        variants = Variant.scoped
        unless params[:show_deleted]
          variants = Variant.active
        end
      elsif current_api_user.has_spree_role?("seller")
        variants = Spree::Variant.where(:product_id => current_api_user.seller.products.map(&:id)).scoped
        unless params[:show_deleted]
          variants = Spree::Variant.where(:product_id => current_api_user.seller.products.map(&:id)).active
        end
      else
        variants = variants.active
      end
    end
    variants
  end
end
