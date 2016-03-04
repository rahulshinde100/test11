class Spree::UserMailer < Spree::BaseMailer
  include TokenGenerator

  def reset_password_instructions(user)
    recipient = user.respond_to?(:id) ? user : Spree.user_class.find(user)
    @user = recipient
    @edit_password_reset_url = spree.edit_spree_user_password_url(:reset_password_token => recipient.reset_password_token)
    @subject = " Password retrieval on ship.li"
    mail(:to => recipient.email, :from => from_address, :subject => @subject,:cc => "", :bcc => "")
  end
  
  def welcome(user, message=nil)
  	@user = user
    @message = message
  	@subject = "Welcome to Ship.li"
    @token = encode(@user.id)
  	mail(:to => user.email, :from => from_address, :subject => @subject)
  end

  def join_us(email)
    @email =email
    @subject = "New User"
    mail(:to => "admin@anchanto.com", :from => from_address, :subject => @subject)
  end

  def join_user(email)
    @email =email
    @subject = "Thank You"
    mail(:to => email, :from => from_address, :subject => @subject)
  end
  
  def welcome_beta_use(user)
    @user = user
    @subject = "Welcome to Ship.li"
    @edit_password_reset_url = spree.edit_spree_user_password_url(:reset_password_token => user.reset_password_token)
    mail(:to => user.email, :from => from_address, :subject => @subject)
  end
  
  def store_credit(user, message)
    @user = user
    @message = message
    @subject = "Store Credit from Ship.li"
    @token = encode(@user.id)
    mail(:to => user.email, :from => from_address, :subject => @subject)
  end
end
