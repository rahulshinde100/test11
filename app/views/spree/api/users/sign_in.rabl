unless @error.blank?
  	node(:error){@error[:error] }
else
	object @user
	attributes :id, :authentication_token, :api_key, :firstname, :lastname, :email, :spree_api_key, :gender_id
	child :spree_roles => :roles do
	  attributes :id,:name
	end
end