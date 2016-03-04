object @seller
attributes *seller_attributes

child :stock_locations do
  attributes :id, :name, :lat, :lng, :address1, :address2, :city,  :state_name, :pickup_at,  :zipcode, :phone, :contact, :email, :operating_hours
end