object @user
attributes :id, :authentication_token, :api_key, :firstname, :lastname, :email, :spree_api_key, :gender_id,:contact ,:dateofbirth, :country_id

child :spree_roles => :roles do
  attributes :id,:name
end