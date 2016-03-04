class PushNotifications #< ActiveRecord::Base

  def push
    #THESE CONFIGURATIONS ARE DEFAULT, IF YOU WANT TO CHANGE UNCOMMENT LINES YOU WANT TO CHANGE
    #configatron.apn.passphrase  = ''
    #configatron.apn.port = 2195
    #configatron.apn.host  = 'gateway.sandbox.push.apple.com'
    configatron.apn.cert = File.join(Rails.root, 'config', 'digitizerAPNS.pem')
    #THE CONFIGURATIONS BELOW ARE FOR PRODUCTION PUSH SERVICES, IF YOU WANT TO CHANGE UNCOMMENT LINES YOU WANT TO CHANGE
    #configatron.apn.host = 'gateway.push.apple.com'
    #configatron.apn.cert = File.join(RAILS_ROOT, 'config', 'apple_push_notification_production.pem')
    #token = "3a6c7ae4 5828ca04 6dc771db 1c61950f e497121d 109ddd07 22756651 2db8b41f"

    
    token = "2e62b856 d9d60d6b d21d9023 46083e83 09fd632a 0045bec5 e96b1979 0699a587"
    #token = "2d1e76ed e57a0ed0 6e58445e 7329d395 985ed3e5 318a8618 fcc69aa7 ebd364cd"
    device = APN::Device.find_by_token(token)
    if device.nil?
      device = APN::Device.create(:token => token)
    end
    #{"aps":{"alert":"New Order R834713346 is placed.","badge":1,"sound":""},"callback":{"type":"1","order_no":"R834713346"}}
    #type=1 new order placed

    notification = APN::Notification.new
    notification.device = device
    notification.badge = 1
    notification.sound = true
    notification.alert = "New Order R200518454 has been placed which includes 3 products"
    notification.custom_properties = {:type => 1, :order_no => "R200518454"}
    notification.save

    APN::Notification.send_notifications
  end


  #this notification will sent to seller admin
  def self.seller_order(order, seller)
    #send this notification to digitizer
    configatron.apn.cert = File.join(Rails.root, 'config', 'digitizerAPNS.pem')
    UserDevice.where(:user_id => seller.users.map(&:id)).each do |user_device|
      notification = APN::Notification.new
      notification.device = user_device.device
      notification.badge = 1
      notification.sound = true
      notification.alert = "New Order #{order.number} has been placed"
      notification.custom_properties = {:type => 1, :order_no => "#{order.number}"}
      notification.save
      APN::Notification.send_notifications([notification])
    end
    
  end

end


