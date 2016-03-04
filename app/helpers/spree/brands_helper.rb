module Spree::BrandsHelper
	def brand_index(brands)
		return '' if brands.empty?
		brands = brands.map{|b| b.name[0].upcase}.uniq
    content_tag :ul , :class=>'brands-list inline' do
    	brands.reduce('') { |c, brand|
        c << content_tag(:li, link_to(" #{brand}", "##{brand}"), :id => "#{brand}-navigator" , :onclick => "return false" , :class => "brand")
      }.html_safe
    end
	end
end
