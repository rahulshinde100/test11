#SMTP setting for Mandill, this setting is responsible for sending email from Fulflmnt Application
if Rails.env.eql?('development')
=begin
  ActionMailer::Base.smtp_settings = {
    :user_name => '25838d2e3629c79e2',
    :password => 'b09b44858a8c5f',
    :address => 'mailtrap.io',
    :domain => 'mailtrap.io',
    :port => '2525',
    :authentication => :cram_md5
  } 
=end
  ActionMailer::Base.smtp_settings = {
    :address => "smtp.mandrillapp.com",
    :port => 587,
    :user_name => 'admin@anchanto.com',
    :password => 'MPTKcWgoJJc6L5EUP5oSbw',
    :authentication => 'plain',
    :enable_starttls_auto => true
  }
else
  #ActionMailer::Base.default_url_options = {protocol:'http', host:'localhost', port:3000}
  #ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    :address => "smtp.mandrillapp.com",
    :port => 587,
    :user_name => 'admin@anchanto.com',
    :password => 'MPTKcWgoJJc6L5EUP5oSbw',
    :authentication => 'plain',
    :enable_starttls_auto => true
  }
end

require 'environment_interceptor'
ActionMailer::Base.register_interceptor(EnvironmentInterceptor)