Spree::Api::TaxonsController.class_eval do
  def products
    if current_api_user.has_spree_role?("seller") || current_api_user.has_spree_role?("seller_store")
      @seller = current_api_user.seller
      @taxon = Spree::Taxon.find_by_permalink!(params[:id])
      return unless @taxon
      @products = @taxon.products.active.where("spree_products.seller_id = #{@seller.id}").order("spree_products.name")
      @products = @products.page(params[:page]).per(30)
    else
      @taxon = Spree::Taxon.find_by_permalink!(params[:id])
      return unless @taxon
      @products = @taxon.products.active.order("spree_products.name")
      @products = @products.page(params[:page]).per(30)
    end
    @total_count = @products.try(:total_count)
  end
end