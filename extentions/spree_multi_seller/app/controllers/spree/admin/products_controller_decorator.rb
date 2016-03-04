require 'archive/zip'
require 'fileutils'

Spree::Admin::ProductsController.class_eval do
	# after_filter :create_email, :only => :create
	before_filter :add_shipping_category, :only => :create
	before_filter :authenticate_spree_user!
    load_and_authorize_resource :class => Spree::Product

	# For this method seller ability will not work
	# collection method is getting called before index method by default.
	# Collection is protected method of product controller , its default method of Spree core.
	# for Spree core seller role is not defined and we can not override it. So for collection seller ability will not work
	# Therefor for index also ability will not work, have to collect products from logged in use fo rseller
	def index 
		session[:return_to] = request.url
		if params[:in_active].present?
			@collection = @collection.where("is_approved = false and is_reject = false and seller_id != ''")
		else
			@collection = @collection.where("is_approved = true and is_reject = false and seller_id != ''")
		end		
		if spree_current_user.has_spree_role?('seller')			
			seller = spree_current_user.seller
			@collection = @collection.where("seller_id = #{seller.id}")
		end
    	respond_with(@collection)
	end


	def new
		if spree_current_user.has_spree_role?('admin')
			@product = Spree::Product.new
		else
			@product = spree_current_user.seller.products.build if spree_current_user.has_spree_role? 'seller'
		end
	end

	def show
	end

	def approved
		if @product.update_attributes({:is_approved => true, :is_reject => false})
			 # Spree::ProductMailer.approve(@product).deliver
                   # Code to active the kit
                   if @product.kit.present?
	                @kit = @product.kit
	                @kit.update_attributes(:is_active => @product.is_approved)
	            end
			redirect_to admin_products_path(:unapprove => 'true'), :notice => "Product is Approved"
		else
			redirect_to admin_products_path(:unapprove => 'true'), :error => "Product is not Approved"
		end
	end

	def reject_reason
		respond_to :js if request.xhr?
	end

	def reject
		if @product.update_attributes(params[:product])
			# Spree::ProductMailer.reject(@product).deliver
			redirect_to admin_products_path(:unapprove => 'true'), :notice => "Product is Reject"
		else
			redirect_to admin_products_path(:unapprove => 'true'), :error => "Product is not Reject"
		end
	end

  protected
   def create_email
   	# Spree::ProductMailer.create_product(@product).deliver
   end

   def add_shipping_category
   	params[:product].merge!(:shipping_category_id => Spree::ShippingCategory.general.id) unless Spree::ShippingCategory.general.nil?
   end
end
