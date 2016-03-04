Spree::BaseHelper.module_eval do

  #server optimize query moved here
  def home_taxonomy
    Spree::Taxon.main_taxons
  end

  def get_seller_list
    Spree::Seller.is_active
  end

  def get_product(product, sort)
    if sort.present?
      product
    else
      product.variants_and_option_values(current_currency).any? ? product.variants.first : product
    end
  end
  def get_taxon_product_count(taxon)
    Spree::Product.active.in_taxon(taxon).uniq.count
    # count = taxon.products.active.count
    # count == 0 ? product_in_taxon(taxon).count : count
  end

  def taxon_product_count(taxon, products)
    count = products.in_taxon(taxon).count
    count == 0 ? Spree::Product.active.in_taxon(taxon).count : count
  end

  def all_taxonomy
    Spree::Taxonomy.select("id, name").all
  end

  def seller_path(permalink)
    # if Rails.env.production?
      return root_path(:subdomain => permalink)
    # else
    #   return "/#{permalink}"
    # end
  end

  def seo_url(taxon)
    return spree.shipli_nested_taxons_path(taxon.permalink)
  end

  def taxons_tree_select(root_taxon, current_taxon, max_level = 1)
      return '' if max_level < 1 || root_taxon.children.empty?
        select("post", "id", root_taxon.children.all.collect {|p| [ p.name, seo_url(p) ] }, {:prompt => '-Select-'} , :class => 'taxon-type')
  end

  def link_to_cart(text = nil)
      return "" if current_spree_page?(spree.cart_path)

      text = text ? h(text) : Spree.t('cart')
      css_class = nil

      if current_order.nil? or current_order.line_items.empty?
        text = "#{text}: (0)"
        css_class = 'empty'
      else
        text = "#{text}: (#{current_order.item_count})  <span class='amount'>#{current_order.display_total.to_html}</span>".html_safe
        css_class = 'full'
      end

      link_to text, "#{main_url}#{spree.cart_path}", :class => "cart-info #{css_class}"
    end

  def product_attributes_tree_select(root_taxon, current_taxon, max_level = 1)
      return '' if max_level < 1 || root_taxon.empty?
         select("sort", "id", root_taxon, {:prompt => "--- sort ---"} , :class => 'taxon-type')
    #     "<select id='sort'>
    #   <option>What's new</option>
    #   <option>Price</option>
    #   <option>Name</option>
    # </select>".html_safe
  end

  def main_url
    return "#{[request.protocol, request.domain, request.port_string].join}"
  end

  def main_seo_url(taxon)
    return "#{main_url}/view/#{taxon.permalink}"
  end

  def taxons_tree_list_category_subcategory(root_taxon, current_taxon, max_level = 1)
      return '' if max_level < 1 || current_taxon.children.empty?
      content_tag :ul, :class => 'taxons-list' do
        current_taxon.children.map do |taxon|
          css_class = (current_taxon && current_taxon.self_and_ancestors.include?(taxon)) ? 'current' : nil
          content_tag :li, :class => css_class do
           link_to(taxon.name, main_seo_url(taxon)) +
           taxons_tree(taxon, current_taxon, max_level - 1)
          end
        end.join("\n").html_safe
      end
   end

  def taxon_tree_responsive(root_taxon, current_taxon, max_level = 1)
   return '' if max_level < 1 || root_taxon.children.empty?
    content_tag :ul, :class => 'taxons-list-responsive' do
      root_taxon.children.unscoped.order(:sequence).map do |taxon|
        unless taxon.name == "Sale"
        if  taxon.parent.present? && taxon.parent.name.capitalize == "categories".capitalize
          content_tag :li, :id => "taxon_id_#{taxon.id}" , :class=> 'four columns main-taxon-list' do

           link_to(taxon.name, main_seo_url(taxon) , :class => 'link-first-level' , :id => main_seo_url(taxon)) +
           taxons_tree(taxon, current_taxon, max_level - 1) +
           taxons_tree_list_category_subcategory_responsive(taxon , current_taxon, max_level = 1 )
          end
        end
        end
      end.join("\n").html_safe

    end
  end


   def taxons_tree_list_category_subcategory_responsive(root_taxon, current_taxon, max_level = 1)
    return '' if max_level < 1 || root_taxon.children.empty?
    content_tag :ul , :class=>'sub-taxon-responsive' do
      root_taxon.children.map do |taxon|
        #css_class = (current_taxon && current_taxon.self_and_ancestors.include?(taxon)) ? 'current' : nil
        content_tag :li do
         link_to(taxon.name, main_seo_url(taxon) , :id => main_seo_url(taxon)) +
         taxons_tree(taxon, current_taxon, max_level - 1)
        end
      end.join("\n").html_safe
    end
 end

 def taxons_tree(root_taxon, current_taxon, max_level = 1)
    return '' if max_level < 1 || root_taxon.children.empty?
    content_tag :ul, class: 'taxons-list' do
      root_taxon.children.map do |taxon|
        css_class = (current_taxon && current_taxon.self_and_ancestors.include?(taxon)) ? 'current' : nil
        content_tag :li, class: css_class do
         link_to(taxon.name, main_seo_url(taxon)) +
         taxons_tree(taxon, current_taxon, max_level - 1)
        end
      end.join("\n").html_safe
    end
  end


 def pin_it_button(product)
    return if product.images.empty?

    url = escape spree.product_url(product)
    media = absolute_product_image(product.images.first)
    description = escape product.name

    link_to("Pin It",
            "http://pinterest.com/pin/create/button/?url=#{url}&media=#{media}&description=#{description}",
            :class => "pin-it-button",
            "count-layout" => "none").html_safe
  end

    def absolute_product_image(image)
      escape absolute_image_url(image.attachment.url)
    end

    def with_format(date)
      if date.today?
        "Today, #{date.strftime("%A, %d %B %Y")}"
      elsif (date - 86400).today?
        "Tomorrow, #{date.strftime("%A, %d %B %Y")}"
      else
        date.strftime("%A, %d %B %Y")
      end
    end

    def breadcrumbs(taxon, separator="&nbsp;&raquo;&nbsp;")
      #raise request.url.inspect
        return "" if current_page?("/") || taxon.nil?
        separator = raw(separator)
        crumbs = [content_tag(:li, link_to(Spree.t(:home), spree.root_path) + separator)]
        if params[:action] == 'shipli_sale'
          crumbs << [content_tag(:li, link_to("Discounts", shipli_sale_path) + separator)]
          if taxon
            crumbs << taxon.ancestors.reject { |t| t.name.capitalize == "Categories".capitalize }.collect { |ancestor| content_tag(:li, link_to(ancestor.name , seo_url(ancestor)) + separator) } unless taxon.ancestors.empty?
            crumbs << content_tag(:li, content_tag(:span, link_to(taxon.name , shipli_sale_taxon_path(taxon)))) # unless taxon.name.capitalize == 'Sale'
          end
        elsif params[:action] == 'warehouse_sale'
          crumbs << [content_tag(:li, link_to("Warehouse Sale", warehouse_sale_path) + separator)]
          if taxon
            crumbs << taxon.ancestors.reject { |t| t.name.capitalize == "Categories".capitalize }.collect { |ancestor| content_tag(:li, link_to(ancestor.name , seo_url(ancestor)) + separator) } unless taxon.ancestors.empty?
            crumbs << content_tag(:li, content_tag(:span, link_to(taxon.name , warehouse_sale_taxon_path(taxon)))) # unless taxon.name.capitalize == 'Sale'
          end
        elsif controller.controller_name == 'brands' && params[:action] == 'show'
          crumbs << [content_tag(:li, link_to("Brands", brands_path) + separator)]
          crumbs << [content_tag(:li, link_to(@brand.name.capitalize, brand_path(@brand)) + separator)]
          if taxon
            crumbs << taxon.ancestors.reject { |t| t.name.capitalize == "Categories".capitalize }.collect { |ancestor| content_tag(:li, link_to(ancestor.name , brands_taxon_path(@brand, ancestor)) + separator) } unless taxon.ancestors.empty?
            crumbs << content_tag(:li, content_tag(:span, link_to(taxon.name , brands_taxon_path(@brand, taxon)))) # unless taxon.name.capitalize == 'Sale'
          end
        else
          if taxon
            crumbs << taxon.ancestors.reject { |t| t.name.capitalize == "Categories".capitalize }.collect { |ancestor| content_tag(:li, link_to(ancestor.name , seo_url(ancestor)) + separator) } unless taxon.ancestors.empty?
            crumbs << content_tag(:li, content_tag(:span, link_to(taxon.name , seo_url(taxon)))) # unless taxon.name.capitalize == 'Sale'
          else
            crumbs << content_tag(:li, content_tag(:span, Spree.t(:products)))
          end
        end
        crumb_list = content_tag(:ul, raw(crumbs.flatten.map{|li| li.mb_chars}.join), class: 'inline')
        content_tag(:nav, crumb_list, id: 'breadcrumbs', class: 'sixteen columns')
    end

    def seller_name
      if(request.subdomain.present? && request.subdomain != "www")
        #{}"Ship.li - #{Spree::Seller.find_by_permalink(request.subdomain).try(:name)}"
        "Channel Manager"
      end
    end

    def brand_url(brand)
      return warehouse_sale_path(:brand => brand.permalink) if params[:action] == "warehouse_sale"
      return brands_taxon_path(brand, @taxon.permalink) if @taxon.present?
      return brands_taxon_path(brand, @seller.permalink) if @seller.present?
    end

    def taxon_url(taxon)
      return brands_taxon_path(@brand, taxon.permalink) if @brand.present?
      return warehouse_sale_taxon_path(taxon.permalink) if params[:action] == "warehouse_sale"
      return seo_url(taxon)
    end

    def seller_url(seller)
      return warehouse_sale_path(:retailer => seller.permalink) if params[:action] == "warehouse_sale"
      return "http://#{seller.permalink}.#{[request.domain, request.port_string].join}/brands/#{@brand.permalink}" if @brand.present?
      return "http://#{seller.permalink}.#{[request.domain, request.port_string].join}/view/#{@taxon.permalink}" if @taxon.present?
    end

       def flash_messages(opts = {})
      opts[:ignore_types] = [:commerce_tracking].concat(Array(opts[:ignore_types]) || [])

      flash.each do |msg_type, text|
        unless opts[:ignore_types].include?(msg_type)
          concat(content_tag :ul, create_li(text.split("<br/>")), class: "flash #{msg_type}")
        end
      end
      nil
    end

    def create_li(errors)
      li = ""
      errors.each do |item|
        li += "<li>#{item}</li>"
      end
      return li.html_safe
    end


    def lhs_menu(taxons=nil, sellers=nil, brands=nil, products=nil, sorted_taxons=nil, sorted_sellers=nil, sorted_brands=nil)
      return '' if taxons.nil? && sellers.nil? && brands.nil?
      limit = 5
      content_tag :ul, class: 'lhs-menu' do
        if taxons.present?
          concat content_tag(:li, "Categories" , :class => "lhs-heading lhs-categories")
          taxons.first(limit).each do |taxon|
            count = products.in_taxon(taxon).count
            concat content_tag(:li, link_to(count <= 0 ? taxon.name.capitalize : "#{taxon.name.capitalize} (#{count})" , taxon_url(taxon)), :class => "lhs-content lhs-categories")
          end
          if taxons.size > limit && !sorted_taxons.nil?
            concat show_content(taxons, products, sorted_taxons)
            concat content_tag(:li, link_to("All" , "#"), :class => "lhs-all", :id => 'categories-all')
          end
        end
        if sellers.present?
          concat content_tag(:li, "Stores" , :class => "lhs-heading lhs-stores", :id=>'lhs-stores')
          sellers.first(limit).each do |seller|
            count = products.where(:seller_id => seller.id).count
            concat content_tag(:li, link_to(count <= 0 ? seller.name.capitalize : "#{seller.name.capitalize} (#{count})" , seller_url(seller)), :class => "lhs-content lhs-stores")
          end
          if sellers.size > limit && !sorted_sellers.nil?
            concat show_sellers(sellers, products, sorted_sellers)
            concat content_tag(:li, link_to("All" , "#"), :class => "lhs-all", :id => 'stores-all')
          end
        end

        if brands.present?
          concat content_tag(:li, "Brands" , :class => "lhs-heading lhs-brands", :id => 'lhs-brands')
          brands.first(limit).each do |brand|
            count = products.where(:brand_id => brand.id).count
            concat content_tag(:li, link_to(count <= 0 ? brand.name.capitalize : "#{brand.name.capitalize} (#{count})" , brand_url(brand)), :class => "lhs-content lhs-brands")
          end
          if brands.size > limit && !sorted_brands.nil?
            concat show_brands(brands, products, sorted_brands)
            concat content_tag(:li, link_to("All" , "#"), :class => "lhs-all icon-double-angle-right" , :id => 'brands-all')
          end
        end
      end
    end

    def show_content(taxons, products, sorted_taxons)
      content_tag(:div, :class => 'all-div', :id => 'categories-all-div') do
        render :partial => "spree/shared/lhs_categories", :locals => {:taxons => taxons, :products => products, :sorted_taxons => sorted_taxons}
      end
    end

    def show_sellers(sellers, products, sorted_sellers)
      content_tag(:div, :class => 'all-div', :id => 'stores-all-div') do
        render :partial => "spree/shared/lhs_stores", :locals => {:sellers => sellers, :products => products, :sorted_sellers => sorted_sellers}
      end
    end

    def show_brands(brands, products, sorted_brands)
      content_tag(:div, :class => 'all-div', :id => 'brands-all-div') do
        render :partial => "spree/shared/lhs_brands", :locals => {:brands => brands, :products => products, :sorted_brands => sorted_brands}
      end
    end

    #ship.li Performance improvements
    def get_header_taxons
      begin
       Spree::Taxonomy.categories.try(:taxons).unscoped.try(:order,'sequence').try(:limit, 100)
      rescue
        return []
      end
    end

    def product_in_taxon(taxon)
      Spree::Product.active.in_taxon(taxon)
    end


    private

    def escape(string)
      URI.escape string, /[^#{URI::PATTERN::UNRESERVED}]/
    end

    def absolute_image_url(url)
      return url if url.starts_with? "http"
      request.protocol + request.host + url
    end

    def get_oms_order_status(order)
      begin
        resp = RestClient.post(OMS_API_PATH, :order_no => order.number,:api_key => OMS_API_KEY,  :content_type => :json, :accept => :json)
        resp = JSON.parse(resp)
        resp["name"]
      rescue
        "completed"
      end
    end
  def preference_field_tag(name, value, options)
    case options[:type]
      when :integer
        number_field_tag(name, value, preference_field_options(options))
      when :boolean
        hidden_field_tag(name, 0, id: "#{name}_hidden") +
            check_box_tag(name, 1, value, preference_field_options(options))
      when :string
        text_field_tag(name, value, preference_field_options(options))
      when :password
        password_field_tag(name, value, preference_field_options(options))
      when :text
        text_area_tag(name, value, preference_field_options(options))
      else
        text_field_tag(name, value, preference_field_options(options))
    end
  end
  def preference_field_options(options)
    field_options = case options[:type]
                      when :integer
                        { :size => 10,
                          :class => 'input_integer' }
                      when :boolean
                        {}
                      when :string
                        { :size => 10,
                          :class => 'input_string fullwidth' }

                      when :password
                        { :size => 10,
                          :class => 'password_string fullwidth' }
                      when :text
                        { :rows => 15,
                          :cols => 85,
                          :class => 'fullwidth' }
                      else
                        { :size => 10,
                          :class => 'input_string fullwidth' }
                    end
    field_options.merge!({
                             :readonly => options[:readonly],
                             :disabled => options[:disabled],
                             :size     => options[:size]
                         })
    if options[:max].present?
      field_options.merge!({
                               :max => options[:max]
                           })
    end
    field_options.merge!({:step => options[:step]}) if options[:step].present?
    if options[:min].present?
      field_options.merge!({
                               :min => options[:min]
                           })
    end
    return field_options
  end
end
