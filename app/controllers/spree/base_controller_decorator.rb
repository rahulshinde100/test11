require 'pp'
Spree::BaseController.class_eval do	
	 #rescue_from Exception, :with => :handle_exceptions

  def breadcrumb_path(path)    
    separator="&nbsp;&raquo;&nbsp;"
    separator = separator.html_safe
  	home_path = {:home => root_path}
    path = {} if path.nil?
    path = home_path.merge!(path)
    links = []
    index = 0
    links << "<nav id='breadcrumbs' class='sixteen columns'>"
    links << "<ul class='inline'>"
    home_path.each do |title, link|
        if(index == home_path.length - 1)
          links << "<li>#{link.to_s.humanize}</li>"
        else
          links << "<li><a href='#{link}' title='#{title}'>#{title.to_s.underscore.humanize}</a>#{separator}</li>"
        end

        index = index + 1
    end
    links << "</ul>"
    links << "</nav>"
    return links.join()
    #links << "</nav>"
    #return links

  end
  def sort(products, sort_by, seq)
  	if sort_by == "price" && seq == "asc"
      products = products.sort_by{|p| (p.special_price || p.price)}.flatten
    elsif sort_by == "price" && seq == "desc"
      products = products.sort_by{|p| -(p.special_price || p.price)}.flatten
    elsif sort_by == "name" && seq == "asc"
      products = products.order("name asc")
    elsif sort_by == "name" && seq == "desc"
      products = products.order("name desc")
    elsif sort_by == "discount" && seq == "asc"
      products = products.sort_by{|p| p.warehouse_discount}.flatten
    elsif sort_by == "discount" && seq == "desc"
      products = products.sort_by{|p| -p.warehouse_discount}.flatten
    end
    products
  end
  def load_retailer
  	subdomain = request.subdomain.split(".")
    # if Rails.env.production?
        @seller = Spree::Seller.is_active.find_by_permalink(subdomain[0]) if subdomain[0].present?
  	# else
   #  	@seller = Spree::Seller.is_active.find_by_permalink(params[:permalink])
  	# end
    if @seller.present?
	    @seller_products = @seller.products.active
	    @categories = @seller.categories
	  end
  end

  private 
		def handle_exceptions(e)
			add_log(e) 
			case e
			when CanCan::AccessDenied
				redirect_to root_url, :alert => "You are not authorise to access this page"
			when ActiveRecord::RecordNotFound
				not_found			
			else
				internal_error(e)
			end
		end
				 
		def not_found
			# Just render view
			render 'errors/not_found', :status => 404
		end
		 
		def internal_error(exception)
			if Rails.env == 'production' || Rails.env == 'staging'
				# Send message to admin email via exception_notification
				request.env['exception_notifier.options'] = {
					:sender_address => "errors@ship.li",
					:exception_recipients => "lareb.nawab@anchanto.com, vishal.zambre@anchanto.com, tejaswini.patil@anchanto.com"
					}
					 
				ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver
					 
					# And just render view
				render :layout => 'layouts/internal_error', :template => 'errors/internal_error', :status => 500, :locals => {:exception => exception}
			else
				throw exception
			end
		end	

		def add_log(exception)
			@request = ActionDispatch::Request.new(request.env)
			ap exception.inspect
			@backtrace  = Rails.respond_to?(:backtrace_cleaner) ? Rails.backtrace_cleaner.send(:filter, exception.backtrace) : exception.backtrace			
			message = ""
			# request section
			message  = "<br/>************************** Request **************************<br/><br/>"
			message += "* URL : <a href=#{@request.url} target='_blank'>#{@request.url}</a><br/>"
			message += "* IP address: #{@request.remote_ip}<br/>"
			message += "* Parameters: #{@request.filtered_parameters.inspect}<br/>"
			message += "* Rails root: #{Rails.root}<br/>"
			 # session section
			message += "<br/>************************** Session **************************<br/><br/>"
			message += "* session id: #{@request.session['session_id'].inspect.html_safe}<br/>"
			message += "* data: #{PP.pp(@request.session, "")}<br/>"

			message += "<br/>************************** Environment **************************<br/><br/>"

			filtered_env = @request.filtered_env
			max = filtered_env.keys.max { |a, b| a.length <=> b.length }
			filtered_env.keys.sort.each do |key|
				message += "* #{[max.length, key, inspect_object(filtered_env[key])]}<br/>"				
			end
			message += "<br/>* Process: #{$$} <br/>"
			message += "* Server : #{`hostname -s`.chomp} <br/>"

			#bacltrack
			message += "<br/>************************** Backtrace **************************<br/><br/>"
			message += @backtrace.join(", ")			
			ap message #if Rails.env == 'production' || Rails.env == 'staging'
			Spree::ErrorLog.create!(:title => defined?(exception) ? exception.class.to_s : "Undefined", :log => message, :status => "New") if Rails.env == 'production' || Rails.env == 'staging'
		end
		
		def inspect_object(object)
      case object
      when Hash, Array
        object.inspect
      when ActionController::Base
        "#{object.controller_name}##{object.action_name}"
      else
        object.to_s
      end
    end
end