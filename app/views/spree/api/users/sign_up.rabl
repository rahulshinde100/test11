unless @error.blank?
  	node(:error){@error[:response] }
else
	object @user
	attributes :id, :authentication_token, :api_key, :firstname, :lastname, :email, :spree_api_key, :gender_id
end