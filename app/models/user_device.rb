class UserDevice < ActiveRecord::Base
  attr_accessible :user_id, :device_id

  belongs_to :user, :class_name => "Spree::User"
  belongs_to :device, :class_name => "APN::Device"
end
