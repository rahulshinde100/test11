class Spree::BusinessType < ActiveRecord::Base
  attr_accessible :business_type, :description
  
  validates_presence_of :business_type

  has_many :sellers, :foreign_key => :business_type_id

  def percentage_based?
  	self.id == 2
  end
  def price_based?
  	self.id == 1
  end
end
