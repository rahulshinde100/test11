Spree::Role.class_eval do
  scope :seller_roles, where("name != 'admin'")
end