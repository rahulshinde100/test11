Spree::Admin::TaxonomiesController.class_eval do

  def category_mapping
    if params[:name].present?
      @taxons = Spree::Taxonomy.categories.taxons.where("name like '%#{params[:name]}%'").collect{|taxon| taxon if (taxon.parent.present? && taxon.parent.parent.present? && taxon.parent.parent.parent.present?)}.compact
    else
      if Spree::Taxonomy.categories.present?
        @taxons = Spree::Taxonomy.categories.taxons.collect{|taxon| taxon if (taxon.parent.present? && taxon.parent.parent.present? && taxon.parent.parent.parent.present?)}.compact
      else
        @taxons = [];
      end
    end
    @taxons = Kaminari.paginate_array(@taxons).page(params[:page]).per(Spree::Config[:admin_products_per_page])
  end

  # Added by Tejaswini Patil
  # To render the sync category view
  # Last modified 13/11/014
  def sync_category
  	@market_places = Spree::MarketPlace.all
  end

  # Added by Tejaswini Patil
  # To import the category file
  # Last modified 13/11/014
  def import_categories
    market_place = Spree::MarketPlace.find_by_id(params[:market_place])
    case market_place.code
    when 'qoo10'
      smp = Spree::SellerMarketPlace.where("market_place_id=? AND api_key IS NOT NULL", params[:market_place]).try(:first)
      @message = sync_all_category_qoo10(smp)
    when 'lazada', 'zalora'
      if !(File.extname(params[:file].original_filename) == ".csv")
       redirect_to sync_category_admin_taxonomies_url, notice: "Please upload a valid csv file"
       return
     else
      @message = Spree::MarketPlaceCategoryList.import(params[:file],params[:market_place].to_i)
     end
    end
  	redirect_to sync_category_admin_taxonomies_url, notice: @message
  end

  def sync_all_category_qoo10(smp)
    @message = ""
    begin
      uri = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/APIList/CommonInfoAPIService.api/GetCatagoryListAll')
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data({'key'=>smp.api_secret_key,'lang_cd'=>''})
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end
      if res.code == "200"
        res_body = Hash.from_xml(res.body).to_json
        res_body = JSON.parse(res_body, :symbolize_names=>true)
        if res_body[:StdCustomResultOfListOfCommonCategoryInfo][:ResultMsg] == nil
          @all_categories = res_body[:StdCustomResultOfListOfCommonCategoryInfo][:ResultObject][:CommonCategoryInfo]
          @all_categories.each do |k|
            category = Spree::MarketPlaceCategoryList.where("category_code=? AND market_place_id=?", k[:CATE_S_CD], smp.market_place_id)
            name = k[:CATE_L_NM]+" << "+ k[:CATE_M_NM]+ " << "+ k[:CATE_S_NM]
            if category.present?
               category.first.update_attributes(:category_code => k[:CATE_S_CD], :name => name)
            else
               category = Spree::MarketPlaceCategoryList.create!(:category_code => k[:CATE_S_CD], :name => name, :market_place_id => smp.market_place_id)
            end
          end
        elsif res_body[:StdCustomResultOfListOfCommonCategoryInfo][:ResultMsg] == "Invalid Access"
          @message = "API call failed due to wrong API Key"
        else
          @message = res_body[:StdCustomResultOfListOfCommonCategoryInfo][:ResultMsg]
        end
      else
        @message = "API call failed please check API Key"
      end
    rescue Exception => e
      @message = e.message
    end
    return @message.empty? ? "Categories Synced" : @message
  end

end
