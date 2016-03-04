Spree::Admin::StockLocationsController.class_eval do
  before_filter :update_params, :only => [:create, :update]
  before_filter :load_seller, :only => [:create, :update]

  def new
    unless params[:return].blank?
      @seller = Spree::Seller.find(params[:seller_id])
      @render_breadcrumb = breadcrumb_path({:sellers => admin_sellers_path, "#{@seller.name}" => admin_seller_path(@seller), :stores => admin_stock_locations_path ,:disable => "New"})
    end
    super
  end

  def create
    if (params[:file] == "file_upload")
      notice = ""
      if (params[:sample_file].present? && params[:sample_file].content_type == "application/vnd.ms-excel")
        upload_stores
        notice = "Store Location added successfully"
      else
        notice = "Invalid file format or file not exist"
      end
      redirect_to params[:return].blank? ? admin_stock_loacations_path : params[:return], :notice => notice
      return
    else
      if @seller.stock_locations.blank?
        params[:stock_location].merge!(:is_warehouse => true)
      end
      @stock_location = @seller.stock_locations.build(params[:stock_location])
      if @stock_location.save
        @stock_location.update_lat_lng
        if params[:return].blank?
          redirect_to admin_stock_locations_path, :notice => "Store Location added successfully"
        else
          redirect_to params[:return], :notice => "Store Location added successfully"
        end
      else
        render :new
      end
    end
  end

  def upload_stores
    store_addresses = Spreadsheet.open params[:sample_file].path
    store_sheet = store_addresses.worksheet(0)
    store_sheet.each_with_index do |row, index|
      next if index == 0
      opts = {:name =>row[1], :email =>row[2], :phone =>row[3], :address1 =>row[4] ,:address2 =>row[5] ,:city =>row[6], :state_name =>row[7], :country_id => Spree::Country.find_by_name(row[8]).id, :zipcode =>row[9], :operating_hours =>row[10], :pickup_at =>row[11], :contact_person_name => row[12] }
      opts.merge!(:seller_id => @seller.id)
      store = Spree::StockLocation.create!(opts)
      store.update_lat_lng
    end
  end
  def change_warehouse
    @seller = Spree::Seller.find_by_permalink(params[:permalink])
    @seller.stock_locations.update_all(:is_warehouse => false)
    @seller.stock_locations.find(params[:id]).update_attributes(:is_warehouse => true)
    redirect_to admin_seller_store_addresses_path(@seller)
  end
  def update
    @stock_location = Spree::StockLocation.find(params[:id])
    if @stock_location.update_attributes(params[:stock_location])
      @stock_location.update_lat_lng
      redirect_to (params[:return].blank? ? admin_seller_store_addresses_path(@seller) : params[:return]), :notice => "Address successfully updated"
    else
      redirect_to admin_seller_store_addresses_path(@seller), :notice => "Oops! Something wrong"
    end
  end

  private
  def update_params
    if spree_current_user.has_spree_role?("admin")
      params[:stock_location].merge!(:seller_id => Spree::Seller.find_by_permalink(params[:stock_location][:seller_id]).try(:id)) unless params[:stock_location].blank?
    else
      params[:stock_location].merge!(:seller_id => spree_current_user.try(:seller).try(:id)) unless params[:stock_location].blank?
    end
    return params[:stock_location]
  end

  def load_seller
    if spree_current_user.has_spree_role?("seller")
      @seller = spree_current_user.seller
    else
      @seller = Spree::Seller.find(params[:stock_location][:seller_id])
    end
  end
end
