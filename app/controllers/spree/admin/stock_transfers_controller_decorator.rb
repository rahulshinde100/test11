Spree::Admin::StockTransfersController.class_eval do


  def index
        @q = Spree::StockTransfer.ransack(search_result)

        @stock_transfers = @q.result
                             .includes(:stock_movements => { :stock_item => :stock_location })
                             .order('created_at DESC')
                             .page(params[:page])
        return  flash.now[:success] = "No record found for selected date" if @stock_transfers.blank?
        if params[:export_type] == "xls" && @stock_transfers.present?
          stock_transfers = Spreadsheet::Workbook.new
          stk_transfer = stock_transfers.create_worksheet :name => 'stock_transfer'
          Spreadsheet::Excel::Internals::SEDOC_ROLOC.update(:light_blue => 0xc3d9f)
          Spreadsheet::Column.singleton_class::COLORS << :light_blue
          white = Spreadsheet::Format.new :color => 'black', :weight => 'bold', :size => 10, :align => 'center', :pattern_fg_color => :light_blue, :pattern => 1
          gray = Spreadsheet::Format.new :color => 'black', :weight => 'bold', :size => 10, :align => 'center', :pattern_fg_color => :white, :pattern => 1
          header_format = Spreadsheet::Format.new :color => 'white', :weight => 'bold', :size => 12, :align => 'center', :text_wrap => true, :pattern_fg_color => :black, :pattern => 1

          stk_transfer.row(0).push "#","Product Name", "Variant", "Manufacturer", "Quantity Received", "Damaged Count","Usable Quantity","PO#","DO#","Total Order Cost","Received Date","Received By","Expiry Date","source","Destination"
          @stock_transfers.each_with_index do |stock_transfer, index|
            stk_transfer.row(index+1).push (index + 1), stock_transfer.destination_movements.collect{|m| "#{m.stock_item.variant.product.name}" }.join(", "), stock_transfer.destination_movements.collect{|m| "#{m.stock_item.variant.name}"}.join(", "), stock_transfer.destination_movements.collect{|m| " #{m.stock_item.variant.product.company.blank? ? m.stock_item.variant.product.seller.name : m.stock_item.variant.product.company}" }.join(", ") , stock_transfer.destination_movements.collect{|m| m.quantity}.join(", "),stock_transfer.damaged_quantity,stock_transfer.destination_movements.collect{|m| m.quantity}.join(", ").to_i - stock_transfer.damaged_quantity.to_i,stock_transfer.delivery_order,stock_transfer.purchase_order,stock_transfer.total_order_cost,stock_transfer.received_date,stock_transfer.received_by,stock_transfer.expiry_date,stock_transfer.source_location.try(:name),stock_transfer.destination_location.try(:name) #{term.created_at.strftime('%b %Y')}", term.created_at.strftime("%H:%m %p")
          end
          stk_transfer.row(0).default_format = header_format
          blob = StringIO.new("")
          stock_transfers.write blob
          #respond with blob object as a file
          send_data blob.string, :type => :xls, :filename => "#{@filename}.xls"
          return
        end

  end

  def get_stcok_locations
    @seller = Spree::Seller.find(params[:seller_id])
    @stock_locations = @seller.stock_locations
    options = []
    @stock_locations.each do |location|
      next if !location.stock_items.present?
      options << "<option value='#{location.id}'>#{location.name}</option>"
    end
    render :json => {:text => options.join(), :count => @stock_locations.count}
    return
  end


  def create
    variants = Hash.new(0)
    params[:variant].each_with_index do |variant_id, i|
      variants[variant_id] += params[:quantity][i].to_i
    end

    begin
      seller_id = spree_current_user.has_spree_role?("admin") ? params[:seller_id] : spree_current_user.seller.id

      if source_location.nil?
        inventory = {:received_date => params[:received_date], :damaged_quantity => params[:damaged_quantity],
        :total_order_cost => params[:total_order_cost], :received_by => params[:received_by], :expiry_date => params[:expiry_date], :delivery_order_scan_copy => params[:delivery_order_scan_copy],
        :delivery_order => params[:delivery_order], :purchase_order => params[:purchase_order],:reference => params[:reference], :seller_id => seller_id}
        @stock_transfer = Spree::StockTransfer.create(inventory)
      else
        @stock_transfer = Spree::StockTransfer.create(:reference => params[:reference], :seller_id => seller_id)
      end
      @stock_transfer.transfer(source_location, destination_location,variants)
      flash[:success] = Spree.t(:stock_successfully_transferred)
      redirect_to admin_stock_transfer_path(@stock_transfer)
    rescue Exception => e
      render :new
      return
    end
  end

  def get_product
    product = Spree::Variant.find(params[:id]).product
    render :json => {:name => product.name, :manufacturer => product.company}
    return
  end

  # Method to import stock on MP's
  def import_product_stock
    @seller = Spree::Seller.find(params[:seller_id])
    if !@seller.present?
        flash[:error] = "Please select seller"
        redirect_to import_stock_admin_sellers_path
        return
    end

    unless File.extname(params[:file].original_filename) == ".xls"
        flash[:error] = "Please upload xls file"
        redirect_to import_stock_admin_sellers_path
        return
    end

    products_stock = Spreadsheet.open params[:file].path
    products_stock_sheet = products_stock.worksheet(0)

    # Product stock upload format
    # row[00] => Brand / Retailer (Optional - for future use - as per Abhimanyu)
    # row[01] => SKU*
    # row[02] => UPC (Optional - for future use - as per Abhimanyu)
    # row[03] => Qty for Qoo10
    # row[04] => Qty for Lazada

     error_hash = []
     @quantity_exceed_error = []
     @qoo10_api_responses = []
     @lazada_api_responses = []
      products_stock_sheet.each_with_index do |row, index|
           row[100] = ""
           if index == 0 || row[1].nil?
              row[100] += "1"
              error_hash << row if !error_hash.include?(row)
              next
           end

           @variant = Spree::Variant.find_by_sku(row[1].to_s)
            if !@variant.present?
               row[100] += "1"
               error_hash << row if !error_hash.include?(row)
               next
            end

            retailer = row[0].to_s
            sku = row[1].to_s
            upc = row[2].to_s
            qty_for_qoo10 = row[3]
            qty_for_lazada = row[4]

            if @variant.present?
                fba_quantity = @variant.fba_quantity
                total_qty_from_xls = qty_for_qoo10.to_i+qty_for_lazada.to_i

                if fba_quantity.to_i < total_qty_from_xls
                  @quantity_exceed_error << fba_quantity
                   row[100] += ",5"
                   error_hash << row if !error_hash.include?(row)
                   next
                end

              @product = @variant.product
              @market_places = Spree::MarketPlace.all

              # 1. FBA stock count validation against both mp's quantity - done
              # 2. MP's stock update method implementation - done
              # 3. Error file generation improvements - done

              @market_places.each do |mp|
                @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND product_id=? AND market_place_id=?", params[:seller_id], @product.id, mp.id).first
                case mp.code
                  when "qoo10"
                    if qty_for_qoo10.present?
                      if @sellers_market_places_product.present?
                          @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, @variant.id).first
                          if @stock_product.present?
                              old_stock_count = @stock_product.count_on_hand
                              new_stock_count = qty_for_qoo10.to_i
                              total_stock_count = old_stock_count.to_i + new_stock_count.to_i
                              @stock_product.update_attributes(:count_on_hand => total_stock_count)
                               final_count_qoo10 = total_stock_count
                          else
                              @stock_product = Spree::StockProduct.create(:sellers_market_places_product_id => @sellers_market_places_product.id, :variant_id => @variant.id, :count_on_hand => qty_for_qoo10.to_i, :virtual_out_of_stock => false)
                               final_count_qoo10 = qty_for_qoo10.to_i
                          end # stock_product present check

                          seller_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", @seller.id, mp.id).first
                          @qoo10_api_response = Spree::StockMovement.stock_update_qoo10(@product, mp.id, final_count_qoo10, @stock_product, seller_market_place, @sellers_market_places_product, final_count_qoo10)

                          if @qoo10_api_response != true
                             @qoo10_api_responses << @qoo10_api_response.to_s
                              row[100] += ",6"
                              error_hash << row if !error_hash.include?(row)
                          end
                          puts '---response - stock update - qoo10---'
                          puts @qoo10_api_response
                          puts '-------------------------------------------------'
                      else
                          row[100] += ",3"
                          error_hash << row if !error_hash.include?(row)
                      end # sellers_market_places_product present check
                    end # qty_for_qoo10 present check
                  when "lazada"
                    if qty_for_lazada.present?
                      if @sellers_market_places_product.present?
                          @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, @variant.id).first
                          if @stock_product.present?
                              old_stock_count = @stock_product.count_on_hand
                              new_stock_count = qty_for_lazada.to_i
                              total_stock_count = old_stock_count.to_i + new_stock_count.to_i
                              @stock_product.update_attributes(:count_on_hand => total_stock_count)
                               final_count_lazada = total_stock_count
                          else
                              @stock_product = Spree::StockProduct.create(:sellers_market_places_product_id => @sellers_market_places_product.id, :variant_id => @variant.id, :count_on_hand => qty_for_lazada.to_i, :virtual_out_of_stock => false)
                               final_count_lazada = qty_for_lazada.to_i
                          end # stock_product present check

                          seller_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", @seller.id, mp.id).first
                          @lazada_api_response = Spree::StockMovement.stock_update_lazada(@product, mp.id, final_count_lazada, @stock_product, seller_market_place, @sellers_market_places_product, final_count_lazada)

                          if @lazada_api_response != true
                             @lazada_api_responses << @lazada_api_response.to_s
                              row[100] += ",7"
                              error_hash << row if !error_hash.include?(row)
                          end
                          puts '---response - stock update - lazada---'
                          puts @lazada_api_response
                          puts '-------------------------------------------------'
                      else
                          row[100] += ",4"
                          error_hash << row if !error_hash.include?(row)
                      end # sellers_market_places_product present check
                    end # qty_for_lazada present check
                end # switch case end

               end # market places loop

            end # variant present

     end # product stock loop (main*)

      if error_hash.present? && error_hash.size >=2
         products_stock_errors(error_hash, @quantity_exceed_error, @qoo10_api_responses, @lazada_api_responses)
      else
         redirect_to import_stock_admin_sellers_path, :notice => "Product Stock Updated Successfully!"
         return
      end
  end

  def products_stock_errors(error_hash, quantity_exceed_error, qoo10_api_response, lazada_api_response)
        errors = Spreadsheet::Workbook.new
        error = errors.create_worksheet :name => 'errors'
        error.row(0).push "Brand / Retailer", "SKU", "UPC", "Qty for Qoo10", "Qty for Lazada", "Total Qty (MP1+MP2) exceeds than FBA quantity", "Qoo10 api error", "Lazada api error"
        red = Spreadsheet::Format.new :color => 'black', :size => 10, :align => 'center', :pattern_fg_color => :red, :pattern => 1
        error_hash.each_with_index do |err, index|
          error.row(index).push err[0], err[1], err[2], err[3], err[4], err[5], err[6] unless index == 0
          err[100].to_s.split(",").each_with_index do |r|
            next unless r.present?
            error.row(index).set_format(r.to_i, red) unless index == 0

            if index != 0
               if qoo10_api_response[index-1].present?
                  error.row(index).push qoo10_api_response[index-1]
               end # end qoo10_api_response present

               if lazada_api_response[index-1].present?
                  error.row(index).push lazada_api_response[index-1]
               end # end lazada_api_response present

               if quantity_exceed_error[index-1].present?
                  error.row(index).push quantity_exceed_error[index-1]
               end # end quantity_exceed_error present
            end # end index not equal to 0

          end # end err[100] loop
        end # end error_hash loop

        blob = StringIO.new("")
        errors.write blob
        #respond with blob object as a file
        send_data blob.string, :type => :xls, :filename => "products_stock_errors.xls"
        return
  end

  # Method to export stock
  def export_product_stock
        @seller = Spree::Seller.find_by_id(params[:seller_id])
        if !@seller.present?
            flash[:error] = "Please select seller"
            redirect_to import_stock_admin_sellers_path
            return
        end

         product_ids = Spree::SellersMarketPlacesProduct.all.map(&:product_id)
         seller_products = @seller.products
         products = seller_products.where("id IN (?)", product_ids) if product_ids.present? && seller_products.present?

         if products.present?
            export_to_excel_products_stock(products)
         else
            flash[:error] = "No product listed!"
            redirect_to import_stock_admin_sellers_path
            return
         end
  end

  def export_to_excel_products_stock(products_collection)
        products = Spreadsheet::Workbook.new
        product = products.create_worksheet :name => 'products'
        product.row(0).push "Brand / Retailer", "SKU", "UPC", "Qty for Qoo10", "Qty for Lazada"
        i = 1
        products_collection.each_with_index do |pr, index|
            variants = []
            if pr.variants.present?
               variants << pr.variants
            else
               variants << pr.master
            end

            variants_all = variants.flatten

            @stock_count_for_qoo10 = 0
            @stock_count_for_lazada = 0
            # Logic for with zero(0) qty stock products which are listed on mp's
            variants_all.each do |v|
              if v.stock_products.present?
               v.stock_products.each do |vsp|
                 if vsp.sellers_market_places_product.present?
                    if vsp.sellers_market_places_product.market_place.code == "qoo10"
                       @stock_count_for_qoo10 = vsp.count_on_hand
                    else
                       @stock_count_for_lazada = vsp.count_on_hand
                    end
                 end # end vsp.sellers_market_places_product present
               end # end variant stock products loop
             else
              if v.product.sellers_market_places_products.present?
                 v.product.sellers_market_places_products.each do |vp_smpp|
                    if vp_smpp.market_place.code == "qoo10"
                       @stock_count_for_qoo10 = 0
                    else
                       @stock_count_for_lazada = 0
                    end
                 end # end vp_smpp loop
             end # v.product.sellers_market_places_products present
            end # v.stock_products present
            product.row(i).push v.product.seller.name, v.sku, "NA", @stock_count_for_qoo10, @stock_count_for_lazada
            i += 1
          end if variants_all.present? # end variants loop

        end if products_collection.present? # end products loop

        blob = StringIO.new("")
        products.write blob
        # respond with blob object as a file
        send_data blob.string, :type => :xls, :filename => "products_stock.xls"
        return
  end

  def stock_setting_load_product
    @product = Spree::Product.find(params[:id])
    respond_to do |format|
      format.html { render :partial=>"/spree/admin/sellers/stock_setting_form"}
    end
  end

  def manage_stock_setting_product
    messages = []
    product = Spree::Product.find(params[:product_id])
    STOCKCONFIG.key(params[:product][:stock_config_type]).to_i
    product.update_column(:stock_config_type, STOCKCONFIG.key(params[:product][:stock_config_type]).to_i)
    product = product.reload
    product_stocks = view_context.stock_manage_with_type(product, params[:seller_market_place_stock_config_details], params[:product][:stock_config_type])
    product_stocks.each do |key, value|
      variant = Spree::Variant.find(key)
      begin
        value.each do |sp_key, stock_count|
          stock_product = Spree::StockProduct.find(sp_key)
          smpp = stock_product.sellers_market_places_product
          market_place = smpp.market_place
          user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", product.seller_id, market_place.id)
          case market_place.code
            when "qoo10"
              res = Spree::StockMovement.stock_update_qoo10(product, market_place.id, stock_count, stock_product, user_market_place.first, smpp, stock_count)
            when "lazada", "zalora"
              res = Spree::StockMovement.stock_update_lazada(product, market_place.id, stock_count, stock_product, user_market_place.first, smpp, stock_count)
          end
          messages << (market_place.name+": "+ res) if res != true
        end
      rescue Exception => e
        messages << e.message
      end
    end
    if messages.present?
      redirect_to :back, :error => messages.join("; ")
    else
      redirect_to :back, :notice => "Product stock setting successfully updated"
    end
  end

  def sync_with_fba
    @product = Spree::Product.find(params[:id])
    msg = []
    if @product.kit.present?
      stock = fetch_kit_fba_stock(@product.kit)
      if @product.kit.update_attribute(:quantity,stock)
        variant= @product.master
        old_quantity = variant.fba_quantity
        variant.quantity_inflations.present? ? (variant.update_column(:fba_quantity,stock) ):(variant.update_attributes(:fba_quantity=>stock) )
        msg = 'Admin/Stock Transfers Controller sync_with_fba Line 289'
        variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
        variant.update_stock_after_change if (!variant.quantity_inflations.present? && old_quantity == stock)
        msg << 'FBA quantity fetch successfully!'
      end
    else
      seller = @product.seller
      seller_market_place = Spree::SellerMarketPlace.where(:seller_id=>seller.id).try(:first)
      #smps = seller.seller_market_places.where(:is_active=>true)
      variants = []
      variants << (@product.variants.present? ? @product.variants : @product.master)
      variants = variants.flatten
      variants.each do |variant|
        old_quantity = variant.fba_quantity
        #Spree::Variant.fetch_qty_from_fba(smps.first,variant) if fetch_fba_qty
        if variant.parent_id.present?
          parent =  Spree::Variant.find(variant.parent_id)
          if parent.product.kit.present?
            stock = fetch_kit_fba_stock(parent.product.kit)
            if parent.product.kit.update_attribute(:quantity,stock)
              v= parent.product.master
              v.quantity_inflations.present? ? (v.update_column(:fba_quantity,stock) ):(v.update_attributes(:fba_quantity=>stock) )
              msg = 'Admin/Stock Transfers Controller sync_with_fba Line 411'
              v.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
              variant.update_stock_after_change if (!variant.quantity_inflations.present? && old_quantity == stock)
              msg << 'FBA quantity fetch successfully!'
            end
          else
            msg << Spree::Variant.fetch_qty_from_fba(seller_market_place, parent)
            parent.reload
            variant.quantity_inflations.present? ? (variant.update_column(:fba_quantity,parent.fba_quantity) ):(variant.update_attributes(:fba_quantity=>parent.fba_quantity) )
            variant.reload
            msg = 'Admin/Stock Transfers Controller sync_with_fba Line 421'
            variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
            stock = variant.fba_quantity
            variant.update_stock_after_change if (!variant.quantity_inflations.present? && old_quantity == stock)
          end
        else
          msg << Spree::Variant.fetch_qty_from_fba(seller_market_place, variant)
          variant.reload
          stock = variant.fba_quantity
          variant.update_stock_after_change if (!variant.quantity_inflations.present? && old_quantity == stock)
        end

      end
    end

msg =  msg.uniq
    if request.xhr?
      render :json => msg.to_json
    end
  end

  def fetch_kit_fba_stock(kit)
    @products = kit.kit_products
    lowest_stock = 0
    @products.each_with_index do |p , ind|
      product = p.product
      variant = p.variant
      seller = product.seller
      seller_market_place = Spree::SellerMarketPlace.where(:seller_id=>seller.id).try(:first)
      msg = Spree::Variant.fetch_qty_from_fba(seller_market_place, variant)
      variant.reload
      qty = (variant.fba_quantity/p.quantity).to_i
      if ind == 0
        lowest_stock = qty
      elsif (ind!=0 && lowest_stock > qty)
        lowest_stock = qty
      end
    end
    return lowest_stock
  end

   protected
   def search_result
    params[:q] = {} unless params[:q]

    if params[:q][:created_at_gt].blank?
      params[:q][:created_at_gt] = Time.zone.now.beginning_of_month
    else
      params[:q][:created_at_gt] = Time.zone.parse(params[:q][:created_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
    end

    if params[:q] && !params[:q][:created_at_lt].blank?
      params[:q][:created_at_lt] = Time.zone.parse(params[:q][:created_at_lt]).end_of_day rescue ""
    else
      params[:q][:created_at_lt] = Time.zone.now.end_of_day
    end
    @filename = "Search Terms from"
    @filename += "#{params[:q][:created_at_gt].to_date}" unless params[:q][:created_at_gt].nil?
    @filename += "_to_#{params[:q][:created_at_lt].to_date}" unless params[:q][:created_at_lt].nil?
    search_result = params[:q]
   end

end

