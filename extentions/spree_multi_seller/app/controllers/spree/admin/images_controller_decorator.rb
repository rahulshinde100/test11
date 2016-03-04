Spree::Admin::ImagesController.class_eval do
  before_filter :verify_seller_product
end
