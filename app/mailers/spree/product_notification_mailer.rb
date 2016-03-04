class Spree::ProductNotificationMailer < Spree::BaseMailer
	include TokenGenerator

  def notify_me(notification)
  	@user = notification.user
  	@notification = notification
  	@subject = "#{notification.variant.name_and_sku} is back in stock"
  	@token = encode(@user.id)
    mail(:to => @user.email, :from => from_address, :subject => @subject)
  end

  def fail_on_fba(email, subject, message, file, file_name)
    @subject = subject
    @message = message
    attachments["report_for_#{file_name}"] = {:mime_type => 'application/xls', :content => file } if file.present?
    mail(:to => email, :from => "no-reply@channel-manager.com", :subject => @subject)
  end

  def product_create_on_mp_status(email, subject, message, file, file_name)
    @subject = subject
    @message = message
    attachments["report_for_#{file_name}"] = {:mime_type => 'application/xls', :content => file } if file.present?
    mail(:to => email, :cc => 'pooja.dudhatra@anchanto.com', :from => "no-reply@channel-manager.com", :subject => @subject)
  end

end
