Spree::Api::ProductsController.class_eval do
  before_filter :add_shipping_category, :only => :create
 def search
   key = params[:keyword]
   q = {"name_or_description_cont"=>"#{key}"}
   @products = product_scope.approved.active.ransack(q).result.page(params[:page])
 end
 
  def seller_products
    if current_api_user.has_spree_role?('admin')
      @products = Spree::Product.all
    else
      @seller = current_api_user.seller
      @products = @seller.products.active
    end
    @products = @products.page(params[:page]).per(params[:per_page])
  end

  def update
    authorize! :update, Spree::Product
    @product = Spree::Product.find_by_permalink(params[:id])
    
    if @product.update_attributes(params[:product])
      #Stock Item
      params[:stock_items].each do |item|
        stock_location = Spree::StockLocation.find(item["stock_location_id"].to_i)
        stock_movement = stock_location.stock_movements.build(:quantity => item["quantity"].to_i)
        stock_movement.stock_item = stock_location.set_up_stock_item(@product.master)
        stock_movement.save
      end unless params[:stock_items].nil?

      unless params[:taxons].nil?
       @product.taxons.destroy_all 
       @product.taxons <<  Spree::Taxon.where(:id => params[:taxons])
      end 

      if params[:product_properties].present?
        @product.product_properties.destroy_all
        params[:product_properties].each do |key,val|
            @product.product_properties << Spree::Property.find_by_name(key).product_properties.build(:value => val)
        end 
      end
      respond_with(@product, :status => 200, :default_template => :show)
    else
      invalid_resource!(@product)
    end
  end

  def destroy
    authorize! :update, Spree::Product
    @product = Spree::Product.find_by_permalink(params[:id])
    @product.destroy
    @response = {:response => "success"}
  end

  def create
    begin
      Spree::Product.transaction do
        if current_api_user.has_spree_role?('admin')
          @product = Spree::Product.new(params[:product])
        else
          @seller = current_api_user.seller
          @product = @seller.products.build(params[:product])
        end

        @product.save!
        params[:product_properties].each do |key,val|
          @product.product_properties << Spree::Property.find_by_name(key).product_properties.build(:value => val)
        end if params[:product_properties].present?

        if params[:product][:prototype_id]
          @prototype = Spree::Prototype.find(params[:product][:prototype_id])
          @product.option_types << @prototype.option_types
        end
        @product.taxons <<  Spree::Taxon.where(:id => params[:taxons])
        # @product.update_attribute_without_callbacks(:shipping_category_id, (Spree::ShippingCategory.general || Spree::ShippingCategory.first).id)
        #Stock Item
        params[:stock_items].each do |item|
          stock_location = Spree::StockLocation.find(item["stock_location_id"].to_i)
          stock_movement = stock_location.stock_movements.build(:quantity => item["quantity"].to_i)
          stock_movement.stock_item = stock_location.set_up_stock_item(@product.master)
          stock_movement.save
        end unless params[:stock_items].nil?

      end
    rescue Exception => e
      @error = {:error => e.message}
      puts "------------------------------------Product Create------------"
      ap e.message
      ap e.backtrace.inspect
      puts "==================================================================="
      return
    end
  end

  def upload_image
    @product = Spree::Product.find(params[:id])
    params[:images].each_with_index do |image, index|
              next if image.empty?
              image_name = @product.save_images(image, index)
              @product.add_image(image_name)
            end
  end

 
  def notify_me
		if current_api_user
			unless current_api_user.notifications.exists?(:variant_id => params[:variant_id].to_i)
				current_api_user.notifications.build(:variant_id => params[:variant_id]).save
        wishlist = Spree::WishedProduct.new(:variant_id => params[:variant_id], :wishlist_id => current_api_user.wishlist.id)
        wishlist.save!
        @response = {:response => " Thank you for your interest in this product. We will keep you posted on its availability."}
        return
      else
        @response = {:response => " You are already registred for the service"}
        return
			end
    else
      @response = {:response => " Please Login first to use this service"}
      return
		end
 end

 def prototypes
  @prototypes = Spree::Prototype.all
 end

 def shipping_categories
  @shipping_categories = Spree::ShippingCategory.all
 end

 def option_types
 # @prototype = Spree::Prototype.find(params[:id])
  @option_types = Spree::OptionType.all
  
 end

 def properties
  @properties = Spree::Property.all
  #raise @properties.inspect
 end

 def tax_categories
  @tax_categories = Spree::TaxCategory.all
 end

 def product_variants
  @product = Spree::Product.find(params[:id])
  @variants = @product.variants.includes([:stock_items])
 end

 def category_products
  @category = Spree::Taxon.find_by_permalink(params[:permalink])
  @products = @category.products.where("name LIKE '%#{params[:name]}%'")
  @products = @products.page(params[:page]).per(params[:per_page])
 end

 def shipli_sale
        @products = []
        @products = Spree::Product.active.sale_products
        @products = Kaminari.paginate_array(@products).page(params[:page])
 end

 def warehouse_sale
      @products = []
      @products = Spree::Product.active.warehouse_sale
      @products = Kaminari.paginate_array(@products).page(params[:page])
  end

  def get_products_for_promotion
    if params[:ids]
      @products = product_scope.where(:kit_id=>nil,:id => params[:ids].split(",")).select([:id,:name,:permalink])
    else
      @products = Spree::Product.active.where(:kit_id=>nil).ransack(params[:q]).result
      respond_with(@products)
    end
  end

 protected
  def add_shipping_category
    params[:product].merge!(:shipping_category_id => (Spree::ShippingCategory.general || Spree::ShippingCategory.first).id)
  end
end