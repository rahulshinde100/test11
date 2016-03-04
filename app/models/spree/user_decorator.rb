Spree::User.class_eval do
	attr_accessible :id,:firstname, :lastname, :dateofbirth, :gender_id, :photo, :country_id, :contact, :authentication_token, :terms_and_condition, :created_at, :deleted_at
	cattr_accessor :current_user
  belongs_to :gender
	belongs_to :country
  has_one :user_device
  # devise :confirmable

  # validates_presence_of :firstname, :lastname, :gender_id, :password, :password_confirmation, :email, :on => :create
  scope :not_deleted, where(:deleted_at => nil)

  #this validation already has been added in Devise, removing from here (reason issue #205)
  #validates_uniqueness_of :email
  #validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Invalid email"
  #validates :password_confirmation, length: { minimum: 6 }

	has_attached_file :photo, :styles => {
    :small => "100x100>",
    :medium => "300x300>",
    :large => "500x500>" },
    :default_url => "/assets/ship.li/default-logo.png"

  has_many :notifications, :class_name => "Spree::ProductNotification", :dependent => :destroy
  has_many :search_terms, :class_name => "Spree::SearchTerm", :dependent => :destroy
  has_many :recent_market_place_changes, :class_name => "Spree::RecentMarketPlaceChange", :dependent => :destroy

  scope :last_updated , lambda { |last_date| where("updated_at >= ?", last_date.to_date.beginning_of_day) }

  def apply_omniauth(omniauth)
    pass = Devise.friendly_token[0,20]
    data = omniauth.extra.try(:raw_info)
    if omniauth['provider'] == "facebook"
      if self.new_record?
        update_attributes({:email => omniauth['info']['email'], :firstname => data.try(:first_name), :lastname => data.try(:last_name), :dateofbirth => data.try(:birthday), :gender_id => Spree::Gender.find_by_name(data.try(:gender)).try(:id), :password => pass, :password_confirmation => pass})
      else
        update_attributes({:firstname => data.try(:first_name), :lastname => data.try(:last_name), :dateofbirth => data.try(:birthday), :gender_id => Spree::Gender.find_by_name(data.try(:gender)).try(:id)})
      end
      # user_authentications.build({:provider => omniauth.provider, :uid => omniauth.uid}) #, :location => omniauth['extra']['raw_info'].has_key?("location") ? omniauth['extra']['raw_info']['location']['name'] : '', :photo => omniauth['info']['image']})
    end
    user_authentications.build({:provider => omniauth.provider, :uid => omniauth.uid})
  end

  def apply_omniauth_api(params)
    pass = Devise.friendly_token[0,20]
    self.email = params['email'] if email.blank?
    update_attributes({:firstname => params['firstname'], :lastname => params['lastname'], :dateofbirth => params['dateofbirth'].to_date, :gender_id => params['gender_id'].to_i, :password => pass, :password_confirmation => pass})
    self.social_login(params['user_authentication'])
  end

  def social_login(params)
    user_authentications.build({:provider => params['provider'], :uid => params['uid'], :location => params['location'], :photo => params['photo']})
  end

  def register_for_apns_notifications(token)
    return false if token.nil?
    UserDevice.transaction do
      device = APN::Device.find_by_token(token)
      if device.nil?
        device = APN::Device.create(:token => token)
      end
      UserDevice.create(:user_id => self.id, :device_id => device.id)
      return true
    end
    return false
  end

  def unregister_for_apns_notifications(token)
    return if token.nil?
    device = APN::Device.find_by_token(token)
    user_device = UserDevice.where(:user_id => self.id, :device_id => device.id)  unless device.nil?
    user_device.destroy_all unless user_device.nil?
  end

  def update_store_credits
    store_credits.expired.update_all(:remaining_amount => 0)
  end

end
