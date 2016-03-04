APN::Device.class_eval do

  has_many :user_devices, :class_name => 'UserDevice'

end