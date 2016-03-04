Spree::StockTransfer.class_eval do
  attr_accessible :seller_id
  belongs_to    :seller
  validates_presence_of :seller_id
end