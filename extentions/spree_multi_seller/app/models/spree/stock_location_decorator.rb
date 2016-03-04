Spree::StockLocation.class_eval do
  attr_accessible :seller_id, :contact, :email, :contact_person_name, :pickup_at, :operating_hours, :lat, :lng, :locname, :state, :is_warehouse
  #, :active, :backorderable_default, :propagate_all_variants, :address1, :address2, :state_name, :phone

  belongs_to    :seller

 	validates_presence_of :seller_id, :country_id, :email, :address1, :name, :contact_person_name
 	validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Invalid email"

	def address #need to change name, change to address
  	address = ["#{self.name}", "#{self.address1}", "#{self.address2}","#{self.city}", "#{self.try(:zipcode)}"].compact
    address.delete("")
    address.join("<br/>")
  end

  def address_pickup #need to change name, change to address

  	address = ["#{self.name}", self.try(:address1).last != ',' ? self.address1 : self.address1[0..-2], self.try(:address2).last != ',' ? self.address2 : self.address2[0..-2],"#{self.city} #{self.try(:state)}", "#{self.country.name} - #{self.try(:zipcode)}"].compact
        address.delete("")
        address.join(", ")
  end

  def state
    self.try(:state_name)
  end

  def geo_location
	  begin
      addr = [self.country.name, self.try(:zipcode)].compact
      addr = addr.join('+')
	    resp = RestClient.get("http://maps.googleapis.com/maps/api/geocode/json?address=#{addr}&sensor=false")
	    resp = JSON.parse(resp)
	    resp['results'].first
	  rescue
	      "error"
	  end
  end

  def update_lat_lng
    puts "--------------------4"
  	resp = self.geo_location
    puts "---------------------1234"
		self.update_attributes({:lat => resp['geometry']['location']['lat'], :lng => resp['geometry']['location']['lng'], :locname => resp['formatted_address']}) unless (resp == "error" || resp.nil?)
  end

  private
  def create_stock_items
    unless self.seller.nil?
      #if any stock location added, system add all variant into that location, which is wrong
      Spree::Variant.where(:product_id => self.seller.products.map(&:id)).active.find_each { |variant| self.propagate_variant(variant) }
    end
  end
end
