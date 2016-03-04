module UrlHelper
  def with_subdomain(subdomain)
    subdomain = (subdomain || "")
    subdomain += "." unless subdomain.empty?
    [request.protocol,subdomain, request.domain, request.port_string].join
  end

  def set_mailer_url_options
    ActionMailer::Base.default_url_options[:host] = with_subdomain(request.subdomain)
  end


  def url_for(options = nil)
    # if Rails.env.production?
      case options
#      when String
#          unless(options == "#")
#            options = [request.protocol, request.domain, request.port_string].join + options unless(options.include?(request.protocol))
#          end
      when Hash
        if options.has_key?(:subdomain)
          options = with_subdomain(options.delete(:subdomain))
        end
      end
    # end
    super    
  end

end