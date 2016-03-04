class EnvironmentInterceptor
  def self.delivering_email message
  	unless Rails.env.production?
	    emails = [] 
	    emails << message.to 
	    emails << message.cc 
	    emails << message.bcc
	    emails = emails.flatten.compact.uniq

	    if Rails.env.staging?
	    	message.to = ['abhijeet.ghude@anchanto.com', 'gajanan.deshpande@anchanto.com']
	    	message.cc = []
	    	message.bcc = []
	    elsif Rails.env.testing?
	    	message.to = ['abhijeet.ghude@anchanto.com', 'gajanan.deshpande@anchanto.com', 'pooja.dudhatra@anchanto.com'] #developer can replace his ID here.
	    	message.cc = [] #developer can replace his ID here.
	    	message.bcc = [] #developer can replace his ID here.
      elsif Rails.env.development?
        #message.to = ['abhijeet.ghude@anchanto.com'] #developer can replace his ID here.
        message.cc = [] #developer can replace his ID here.
        message.bcc = [] #developer can replace his ID here.
	    else
	    	message.to = ['abhijeet.ghude@anchanto.com', 'gajanan.deshpande@anchanto.com'] #developer can replace his ID here.
	    	message.cc = [] #developer can replace his ID here.
	    	message.bcc = [] #developer can replace his ID here.
	    end
	    message.subject = "[#{Rails.env.upcase}] #{message.subject}"
	  end
  end
end