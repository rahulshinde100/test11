class Subdomain
  def self.matches?(request)
    # if Rails.env.production?
      request.subdomain.present? && request.subdomain != 'www'
    # else
    #   false
    # end
  end
end  