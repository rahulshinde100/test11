class CustomMailer < ActionMailer::Base
  # Custom order export attached excel in mail 
  def custom_order_export(email, subject, body,file=nil,file_name=nil)
    emails = []
    if email.present?
      emails << email
    else
      emails << 'abhijeet.ghude@anchanto.com'
    end
    @body = body
    emails = emails.flatten
    attachments["#{file_name.present? ? file_name : 'file_name'}.xls"] = {:mime_type => 'application/xls', :content => file } if file.present?
    #mail(:to => emails,:bcc => 'nitin.khairnar@anchanto.com', :cc =>'abhijeet.ghude@anchanto.com' , :subject => subject)
    mail(:to => emails, :cc =>'abhijeet.ghude@anchanto.com' , :subject => subject)
  end
end