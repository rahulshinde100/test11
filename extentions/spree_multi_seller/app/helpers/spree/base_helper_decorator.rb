Spree::BaseHelper.module_eval do
	def check(boolean, text = nil)
    style = text.nil? ? "" : "text-indent: 18px;"
		if boolean
			content_tag(:span, text, :class => "state address", :style => style)
		else
			content_tag(:span, text, :class => "state complete", :style => style)
		end
	end


end