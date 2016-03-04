class Spree::StoreAddress < ActiveRecord::Base
  attr_accessible :seller_id, :address, :city, :state, :country_id, :zipcode, :contact, :email, :web_url, :name, :pickup_at, :operating_hours, :lat, :lng, :locname
 
 	validates_presence_of :seller_id, :country_id, :email, :address, :city, :name, :operating_hours
 	validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Invalid email"
	belongs_to :seller
	belongs_to :country

	def st_address
  	address = ["#{self.address},", "#{self.city} #{self.try(:state)},", "#{self.country.name} - #{self.try(:zipcode)}"].compact
    address.delete("")
    address.join("<br/>")
  end

  def geo_location
	  begin
	    resp = RestClient.get("http://maps.googleapis.com/maps/api/geocode/json?address=#{self.country.name}+#{self.zipcode}&sensor=false")
	    resp = JSON.parse(resp)
	    resp['results'].first
	  rescue
	      "error"
	  end
  end

  def update_lat_lng
  	resp = self.geo_location
		self.update_attributes({:lat => resp['geometry']['location']['lat'], :lng => resp['geometry']['location']['lng'], :locname => resp['formatted_address']}) unless resp.blank?
  end
end
