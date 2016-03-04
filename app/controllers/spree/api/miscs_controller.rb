module Spree
	module Api
		class MiscsController < Spree::Api::BaseController
		  def terms_conditions
		  	@terms_conditions = {:contents =>  ActionView::Base.full_sanitizer.sanitize(Spree::Page.find_by_permalink('terms-of-use').body).html_safe }
		  end

		  def about_us
			@about_us = {:contents => Spree::Page.find_by_permalink('about-us').body,:permalink => Spree::Page.find_by_permalink('about-us').permalink }
		  end
		end
	end
end
