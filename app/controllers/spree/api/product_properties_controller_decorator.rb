Spree::Api::ProductPropertiesController.class_eval do
	def create
        authorize! :create, Spree::ProductProperty
        @product = Spree::Product.find(params[:product_id]) 
        params[:product_properties].each do |key,val|
        	Spree::Property.find_by_presentation(key).product_properties.build(:value => val)
        end
         @response = {:response => "Property added successfuly"}
    end


end