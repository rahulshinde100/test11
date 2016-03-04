 
  if @variants
    node(:count) { @variants.count }
    node(:total_count) { @variants.total_count }
    node(:current_page) { params[:page] ? params[:page].to_i : 1 }
    node(:per_page) { params[:per_page] || Kaminari.config.default_per_page }
    node(:pages) { @variants.num_pages }
    child @variants => :variants do |variant |
      attributes *variant_attributes
      child(:images => :images) { extends "spree/api/images/show" }
      child(:option_values => :option_values ) do
  	    attributes *option_value_attributes
  	end
    end
  else
    node(:count) { 0 }
    node(:total_count) { 0 }
    node(:current_page) { params[:page] ? params[:page].to_i : 1 }
    node(:per_page) { params[:per_page] || Kaminari.config.default_per_page }
    node(:pages) { 0 }
    node(:variants) { [] }

  end

