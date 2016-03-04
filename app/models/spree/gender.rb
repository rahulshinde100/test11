class Spree::Gender < ActiveRecord::Base
  attr_accessible :name, :position

  has_many :users
end
