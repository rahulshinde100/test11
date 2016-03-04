Spree::Admin::VariantsController.class_eval do
  before_filter :verify_seller_product, :except => [:update_positions, :get_new_variants, :get_updated_variants, :update_on_fba, :create_on_fba ]
end
