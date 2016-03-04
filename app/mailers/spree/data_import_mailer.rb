module Spree
  class DataImportMailer < BaseMailer
  	default from: 'no-reply@channel-manager.com'
  	
  	def data_imported(email, subject, seller, file, file_name)
      @seller = seller
      @file_name = file_name
      attachments["report_for_#{file_name}"] = {:mime_type => 'application/xls', :content => file } if file.present?
      mail(:to => email, :subject => subject)
    end
    
    def promotion_quantity_inflation_end(data)
      @data = data
      if Rails.env.eql?('production')
        @cc = ["abhijeet.ghude@anchanto.com"]
        @to = ["abhimanyu.kashikar@anchanto.com", "ritika.shetty@anchanto.com", "swapnil.gadewar@anchanto.com", "cecile.courbon@anchanto.com"]
      elsif Rails.env.eql?('development')  
        @cc = []
        @to = ["abhijeet.ghude@anchanto.com"]
      else  
        @cc = ["abhijeet.ghude@anchanto.com"]
        @to = ["gajanan.deshpande@anchanto.com"]
      end
      @subject = "Channel Manager | Product Inflation Report | Promotion Ends"
      mail(:to =>@to, :cc=>@cc, :subject => @subject)
    end

    def stock_update_notification(data)
      @data = data
      if Rails.env.eql?('production')
        @cc = ["abhijeet.ghude@anchanto.com"]
        @to = ["abhimanyu.kashikar@anchanto.com", "ritika.shetty@anchanto.com", "swapnil.gadewar@anchanto.com", "cecile.courbon@anchanto.com"]
      elsif Rails.env.eql?('development')
        @cc = []
        @to = ["abhijeet.ghude@anchanto.com"]
      else
        @cc = ["abhijeet.ghude@anchanto.com"]
        @to = ["gajanan.deshpande@anchanto.com"]
      end
      @subject = "Channel Manager | Stock change on FBA synchronized with CM"
      mail(:to =>@to, :cc=>@cc, :subject => @subject)
    end

  end
end