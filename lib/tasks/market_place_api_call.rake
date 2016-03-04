require 'csv'
require 'whenever'
require "#{Rails.root}/app/helpers/application_helper"
include ApplicationHelper

namespace :market_place_api_calls do

  desc "Fetch orders from market places and save to switch fabric"
  task :check_for_new_order => :environment do
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_success ||= Logger.new("#{Rails.root}/log/cron/success.log")
    my_error ||= Logger.new("#{Rails.root}/log/cron/error.log")
    Spree::SellerMarketPlace.where(:is_active=>true).each do |smp|
      @res = "" 
      case smp.market_place.code
      when 'qoo10'
        if !smp.api_secret_key.nil?
          @res = order_fetch_qoo10(smp)
          my_logger.info(smp.market_place.name+"-"+smp.seller.name+"-"+ @res) if smp.seller.present?
        else
          my_logger.info(smp.market_place.name+"-"+smp.seller.name+"-"+"Api Secret Key is not generated") if smp.seller.present?
        end
      when 'lazada', 'zalora'
        @res = order_fetch_lazada(smp)
        my_logger.info(smp.market_place.name+"-"+smp.seller.name+"-"+ @res) if smp.seller.present?
      end
      if @res.present? && @res.split(":")[0] == "failed"
        body = "Please take action on following orders are not able to sync with Channel Manager due to following reasons <br /><br />" + @res.to_s
        subject = "Channel Manager | Order sync failed for following orders" 
        CustomMailer.custom_order_export("abhijeet.ghude@anchanto.com",subject,body).deliver 
      end
    end
  end

  desc "Sync all the pending variants which are not yet listed on market place"
  task :sync_market_place_variants => :environment do
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_success ||= Logger.new("#{Rails.root}/log/cron/success.log")
    my_error ||= Logger.new("#{Rails.root}/log/cron/error.log")
    @sync_market_place_variants = Spree::SyncMarketPlaceVariant.all
    @sync_market_place_variants.each do |smpv|
      sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND product_id=? AND market_place_id=?", smpv.seller.id, smpv.product.id, smpv.market_place.id).first
      @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", sellers_market_places_product.id, smpv.variant.id).first rescue nil
      @stock_product = Spree::StockProduct.create(:sellers_market_places_product_id=>sellers_market_places_product.id, :variant_id=>smpv.variant.id, :count_on_hand=>0) if !@stock_product.present?
      quantity = (@stock_product.present? ? @stock_product.count_on_hand.to_i : 0)
      @product = smpv.product
      option_name = smpv.variant.option_values.first.option_type.presentation
      option_value = smpv.variant.option_values.first.presentation
      variant_price = smpv.variant.price
      #variant_selling_price = smpv.variant.selling_price
      variant_selling_price = ((smpv.variant.special_price.to_f > 0 && smpv.variant.special_price.to_f < smpv.variant.selling_price.to_f) ? smpv.variant.special_price.to_f : "")
      variant_sku = smpv.variant.sku
      case smpv.market_place.code
      when 'lazada' , 'zalora'
        res = listing_products_lazada(@product, sellers_market_places_product, option_name, option_value, variant_price, variant_selling_price, quantity, variant_sku)
        smpv.delete
        if res == true
          #smpv.delete
        else
          my_logger.info(smpv.market_place.name+"-"+smpv.seller.name+"-"+ res) if smp.seller.present?
        end
      end
    end if @sync_market_place_variants.present?
  end

  desc "Fetch cancel orders from market places"
  task :check_for_cancel_order => :environment do
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_success ||= Logger.new("#{Rails.root}/log/cron/success.log")
    my_error ||= Logger.new("#{Rails.root}/log/cron/error.log")
    Spree::SellerMarketPlace.where(:is_active=> true).each do |smp|
      case smp.market_place.code
      when 'qoo10'
        if !smp.api_secret_key.nil?
          res = cancel_order_fetch_qoo10(smp)
          my_logger.info(smp.market_place.name+"-"+smp.seller.name+"-"+ res) if smp.seller.present?
        else
          my_logger.info(smp.market_place.name+"-"+smp.seller.name+"-"+"Api Secret Key is not generated") if smp.seller.present?
        end
      when 'lazada' , 'zalora'
        res = cancel_order_fetch_lazada(smp)
        my_logger.info(smp.market_place.name+"-"+smp.seller.name+"-"+ res) if smp.seller.present?
      end
    end
  end

  desc "Sync order status FBA to MP"
  task :update_market_place_order_status => :environment do
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_success ||= Logger.new("#{Rails.root}/log/cron/success.log")
    my_error ||= Logger.new("#{Rails.root}/log/cron/error.log")
    @res = nil
    Spree::MarketPlace.all.each do |mp|
      case mp.code
        when 'qoo10'
          #@res = change_order_status_on_qsm(mp)
        when 'lazada' , 'zalora'
          @res = change_order_status_on_lazada(mp)
      end
        #my_logger.info(mp.first.market_place.name+"-"+mp.first.seller.name+"-"+ @res) if mp.seller.present?
    end
  end

  desc "Sync all order from MarketPlaces to SF to FBA"
  task :sync_market_place_orders_to_fba => :environment do
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_success ||= Logger.new("#{Rails.root}/log/cron/success.log")
    my_error ||= Logger.new("#{Rails.root}/log/cron/error.log")
    all_partial_orders = Spree::Order.includes(:line_items).where("spree_line_items.id is not null AND fulflmnt_tracking_no is null AND is_cancel=false")
    if all_partial_orders.present?
      Spree::Order.push_to_fba(all_partial_orders.map(&:cart_no).uniq)
      my_logger.info(smp.market_place.name+"-"+smp.seller.name+"-"+ res) if smp.seller.present?
    end
  end

  desc "Fetch market Place order status to SF to FBA"
  task :fetch_market_place_order_status => :environment do
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_success ||= Logger.new("#{Rails.root}/log/cron/success.log")
    my_error ||= Logger.new("#{Rails.root}/log/cron/error.log")
    messages = ""
    @res = ""
    Spree::SellerMarketPlace.where(:is_active=> true).each do |smp|
      case smp.market_place.code
        when 'qoo10'
          @res = fetch_qoo10_delivered_orders(smp)
        when 'zalora', 'lazada'
          @res = Spree::Order.shipped_or_delivered_order_fetch_lazada(smp)
      end
      message = smp.market_place.name+"<br />"+smp.seller.name+"<br />"+ @res.to_s+"<br />" if smp.seller.present?
      messages += message if @res.present?
      my_logger.info(message) if message.present? 
    end
    # if messages.present?
      # subject = "Channel Manger | Order status update on FBA"
      # body = "Please take action on following order is not able to change order state <br /><br />"
      # body += messages 
      # CustomMailer.custom_order_export("abhijeet.ghude@anchanto.com",subject, body).deliver
    # end   
  end

  desc "Fetch order invoice for Lazada and push to FBA"
  task :fetch_order_invoice_for_lazada => :environment do
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_success ||= Logger.new("#{Rails.root}/log/cron/success.log")
    my_error ||= Logger.new("#{Rails.root}/log/cron/error.log")
    Spree::SellerMarketPlace.where(:is_active=> true).each do |smp|
      case smp.market_place.code
        when 'lazada' , 'zalora'
          res = fetch_invoice_from_lazada(smp)
          my_logger.info(smp.market_place.name+"-"+smp.seller.name+"-"+ res) if smp.seller.present?
      end
    end
  end

  desc "Sync product quantity from FBA and update to market place according to stock setting currently available"
  task :sync_product_quantity_from_fba => :environment do
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_success ||= Logger.new("#{Rails.root}/log/cron/success.log")
    my_error ||= Logger.new("#{Rails.root}/log/cron/error.log")
    Spree::Seller.all.each do|seller|
      res = update_stock_for_seller(seller, true)
      my_logger.info(seller.name+"-"+ res) if smp.seller.present?
    end
  end

  desc "Sync selected product with FBA kit products to MP"
  task :sync_fba_kit_products => :environment do
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_success ||= Logger.new("#{Rails.root}/log/cron/success.log")
    my_error ||= Logger.new("#{Rails.root}/log/cron/error.log")
    skus=["LZ_Promo_G1304402_G1330002", "LZ_Promo_G1756800_G0782103", "LZ_Promo_G1364601_G1486900", "LZ_Promo_K1447400_G1647300", "LZ_Promo_K1447400_G1690400", "LZ_Promo_G1174200_G1581400", "LZ_Promo_G1174200_G1581500", "LZ_Promo_G1732800_G0782103", "LZ_Promo_Y0126500_G0953900_G0782103", 
      "LZ_Promo_Y0126500_G0954000_G0782103", "LZ_Promo_G1356900_G1418300", "LZ_Promo_G1314502_G0677503", "LZ_Promo_A7123400_A7123400", "LZ_Promo_G1106802_G1321300", "LZ_Promo_G0879703_G1031900", "LZ_Promo_G1321300_A7081500_G0185004"]
    stok_values = {}  
    skus.each do |sku|
      variant = Spree::Variant.find_by_sku(sku)
      if variant.present?
        product = variant.product
        type = STOCKCONFIG[product.stock_config_type] == "default" ? STOCKCONFIG[product.seller.stock_config_type] : STOCKCONFIG[product.stock_config_type] 
        smps = product.seller.seller_market_places.where(:is_active=>true)
        mps = product.seller.market_places.where("spree_market_places.id IN (?)", smps.map(&:market_place_id))
        begin
          Spree::Variant.fetch_qty_from_fba(smps.first,variant)
          stock_products = variant.stock_products.where("sellers_market_places_product_id IN (?)", product.sellers_market_places_products.where("market_place_id IN (?)",smps.map(&:market_place_id)).map(&:id))
          if stock_products.present?
            case type
              when "fixed_quantity"
                #stok_values.merge!(variant.id=>Spree::StockProduct.fixed_quantity_setting(stock_products, variant, mps))
              when "percentage_quantity"
                stok_values.merge!(variant.id=>Spree::StockProduct.fixed_quantity_setting(stock_products, variant, mps))
                #stok_values.merge!(variant.id=>Spree::StockProduct.percentage_quantity_setting(stock_products, variant, mps))
              when "flat_quantity"      
                stok_values.merge!(variant.id=>Spree::StockProduct.flat_quantity_setting(stock_products, variant, mps))
            end # end of case
          end  
        rescue Exception => e
        end
      end
    end
    update_stock_market_places(stok_values)  
  end
  
  desc "Sync order status from FBA to SF whichever missed to update to complete"
  task :complete_order_status_from_fba => :environment do
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_success ||= Logger.new("#{Rails.root}/log/cron/success.log")
    my_error ||= Logger.new("#{Rails.root}/log/cron/error.log")
    cart_nos = Spree::Order.where("fulflmnt_state NOT IN (?)",["complete", "customer_complete"]).map(&:cart_no).uniq
    cart_nos.each do |cn|
      orders = Spree::Order.where("cart_no=?", cn)
      if orders.map(&:fulflmnt_state).include?("complete")
        orders.each do |ord|
          ord.update_column(:fulflmnt_state, "complete") if ord.fulflmnt_state != "cancel"
        end
      elsif orders.map(&:fulflmnt_state).include?("customer_complete")  
        orders.each do |ord|
          ord.update_column(:fulflmnt_state, "customer_complete") if ord.fulflmnt_state != "cancel"
        end
      end  
    end
  end
  
  desc "Generate weekly report fot stock and order for each seller"
  task :generate_weekly_report_for_seller => :environment do
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_success ||= Logger.new("#{Rails.root}/log/cron/success.log")
    my_error ||= Logger.new("#{Rails.root}/log/cron/error.log")
    start_week=(Time.zone.now - 1.week).beginning_of_week
    end_week=(Time.zone.now - 1.week).end_of_week
    start_month=Time.zone.now.beginning_of_month
    end_month=Time.zone.now.end_of_month
    start_year=Time.zone.now.beginning_of_year
    end_year=Time.zone.now.end_of_year
    @excel_hash = {}
    total_current_stock = []
    current_stock = []
    total_stock_sale = []
    stock_sale = []
    total_orders = []
    orders = []
    total_canceled_orders = []
    canceled_orders = []
    
    # All seller current stock
    total_current_stock << ["Stock Details", "Usable Stock", "Unusable Stock", "Cost of Usable Stock", "Cost of Unusable Stock"]
    current_stock << ["Brand", "Sku", "Cost Price", "Usable Stock", "Unusable Stock", "Cost of Usable Stock", "Cost of Unusable Stock", "Product Name"] 
  
    # All sellers sale
    total_stock_sale << ["Brand", start_week.strftime("%B %d").to_s, end_week.strftime("%B %d").to_s, start_month.strftime("%B %d").to_s, "Till Date", "YTD", " "]
    total_stock_sale << [" ", "Unit Sold", "Sale", "Unit Sold", "Sale", "Unit Sold", "Sale"]
    stock_sale << [" ", " ", " ", start_week.strftime("%B %d").to_s, end_week.strftime("%B %d").to_s, start_month.strftime("%B %d").to_s, "Till Date", "YTD", " "]
    stock_sale << ["Brand", "Sku", "Retail Price", "Units Sold", "Sale", "Units Sold", "Sale", "Units Sold", "Sale", "Product Name"]
    canceled_line_items_week = Spree::LineItem.includes("order").where("spree_orders.is_cancel=true").where(:spree_orders=>{:order_date=>start_week..end_week})
    canceled_line_items_month = Spree::LineItem.includes("order").where("spree_orders.is_cancel=true").where(:spree_orders=>{:order_date=>start_month..end_month})
    canceled_line_items_year = Spree::LineItem.includes("order").where("spree_orders.is_cancel=true").where(:spree_orders=>{:order_date=>start_year..end_year})
    canceled_qty_week = canceled_line_items_week.sum(&:quantity)
    canceled_qty_month = canceled_line_items_month.sum(&:quantity)
    canceled_qty_year = canceled_line_items_year.sum(&:quantity)
    canceled_value_week = line_items_price_calculations(canceled_line_items_week)
    canceled_value_month = line_items_price_calculations(canceled_line_items_month)
    canceled_value_year = line_items_price_calculations(canceled_line_items_year)
    total_canceled_orders_on_sales = ["Canceled Order", canceled_qty_week, canceled_value_week, canceled_qty_month, canceled_value_month, canceled_qty_year, canceled_value_year]
    
    # All sellers orders
    total_orders << ["Brand", "Total Order Value", "Total Units Sold", "Total Orders"]
    orders << ["Brand", "Order No", "Cart No", "Order Date(dd-mm-yyyy)", "Customer Pickup", "Order Total", "Shipping Charges", "Order Total Value", "Total Products", "Total Units"]  
  
    # All sellers canceled orders
    total_canceled_orders << ["Brand", "Total Order Value", "Total Units Canceled", "Total Orders"]
    canceled_orders << ["Brand", "Order No", "Cart No", "Order Date(dd-mm-yyyy)", "Customer Pickup", "Order Total", "Total Products", "Total Units", "Cancelation Date"]  
    
    Spree::Seller.where(:is_active=>true).all.each do |seller|
      current_stock_hash = seller_weekly_report_current_stock(seller)
      total_current_stock << [seller.name, current_stock_hash["usable_stock"], current_stock_hash["unusable_stock"], current_stock_hash["cost_usable_stock"], current_stock_hash["cost_unusable_stock"]]
      current_stock += current_stock_hash["products"]
      
      stock_sale_hash = seller_weekly_report_stock_sale(seller)
      total_stock_sale << [seller.name, stock_sale_hash["units_sold_week"], stock_sale_hash["sale_week"], stock_sale_hash["units_sold_month"], stock_sale_hash["sale_month"], stock_sale_hash["units_sold_year"], stock_sale_hash["sale_year"] ]
      stock_sale += stock_sale_hash["products"]
      
      order_hash = seller_weekly_report_orders(seller)
      total_orders << [seller.name, order_hash["total_order_value"], order_hash["total_units_sold"], order_hash["total_orders"]]
      orders += order_hash["orders"]
  
      canceled_order_hash = seller_weekly_report_canceled_orders(seller)
      total_canceled_orders << [seller.name, canceled_order_hash["total_order_value"], canceled_order_hash["total_units_sold"], canceled_order_hash["total_orders"]]
      canceled_orders += canceled_order_hash["orders"]
    end
    total_current_stock << []
    total_current_stock += current_stock
    
    total_stock_sale << []
    total_stock_sale << total_canceled_orders_on_sales
    total_stock_sale << []
    total_stock_sale += stock_sale
    
    total_orders << []
    total_orders += orders
  
    total_canceled_orders << []
    total_canceled_orders += canceled_orders
    
    report_summary = weekly_report_summary 
    
    @excel_hash.merge!("Current Stock"=> total_current_stock, "Stock Sale Report"=> total_stock_sale, "Sale Report"=> total_orders, "Canceled Orders" => total_canceled_orders, "Report Summary" => report_summary)
    
    subject = "Channel Manager | Weekly Report"
    att_name = "Channel_Manager_Weekly_Report_"+Time.now().strftime("%d%m%Y%s").to_s   
    CustomMailer.custom_order_export(["cecile.courbon@anchanto.com", "abhimanyu.kashikar@anchanto.com", "ritika.shetty@anchanto.com"], subject, "Channel Manager Report Summary", generate_excel_multi_worksheet(@excel_hash), att_name).deliver
  end
  
  desc "Check for quantity inflation promotion end"
  task :check_quantity_inflation_promotions => :environment do
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_success ||= Logger.new("#{Rails.root}/log/cron/success.log")
    my_error ||= Logger.new("#{Rails.root}/log/cron/error.log")
    begin
      ord_qty_hash = []
      ord_qty_daily_hash = []
      tdate = Time.now().to_date
      
      # Promotion daily report
      qty_infs_daily = Spree::QuantityInflation.all
      market_places = Spree::MarketPlace.all
      heading = ["Seller Name", "Product Name", "SKU", "Total Carts Sold", "Total Units Sold", "Total Units to Order", "Todays Carts Sold", "Todays Units Sold", "Todays Units to Order", "Promotion End Date", "Stock on Marketplaces"]
      heading1 = ["","","Daily Product Inflation Report"]
      heading2 = ["","","","","","","","","","(DD/MM/YYYY)"] + market_places.map(&:name)
      ord_qty_daily_hash << heading1
      ord_qty_daily_hash << heading
      ord_qty_daily_hash << heading2 
      qty_infs_daily.each do |qty_inf|
        qty_inf_hash = []
        q_hash = qty_inf.daily_promotion_report
        variant_id = q_hash.keys.try(:first)
        variant = Spree::Variant.find(variant_id)
        qty_inf_hash = q_hash.values.try(:first)
        market_places.each do |mp|
          sp = variant.stock_products.includes("sellers_market_places_product").where("spree_sellers_market_places_products.market_place_id=?", mp.id).try(:first)
          qty_inf_hash = qty_inf_hash + [sp.present? ? sp.count_on_hand : "-"]  
        end
        ord_qty_daily_hash << qty_inf_hash 
      end
      body = "Dear Team,<br />"
      body += "<p>Please find the attached daily report for products on promotion. Attached file indicates the total units to be ordered from the source. Also, note that the quantity for these products is currently available on the marketplace based on the setting selected when the inflation request was submitted.</p><br />PFA...<br /><br />"
      subject = "Channel Manager | Daily Inflation Report"
      att_name = "Channel_Manager_Daily_Inflation_Report_"+Time.now().strftime("%d%m%Y%s").to_s
      if Rails.env.eql?('production')
        emails = ["abhimanyu.kashikar@anchanto.com", "ritika.shetty@anchanto.com", "swapnil.gadewar@anchanto.com", "cecile.courbon@anchanto.com", "abhijeet.ghude@anchanto.com", "nitin.khairnar@anchanto.com"]
      elsif Rails.env.eql?('development')  
        emails = ["abhijeet.ghude@anchanto.com"]
      else  
        emails = ["gajanan.deshpande@anchanto.com", "abhijeet.ghude@anchanto.com", "nitin.khairnar@anchanto.com"]
      end
      CustomMailer.custom_order_export(emails, subject, body, generate_excel(ord_qty_daily_hash, heading), att_name).deliver if ord_qty_daily_hash.present? && ord_qty_daily_hash.count > 3 

      # Promotion end report 
      qty_infs = Spree::QuantityInflation.where(:end_date=>tdate.to_date.beginning_of_day..tdate.to_date.end_of_day)
      qty_infs.each do |qty_inf|
        ord_qty_hash << qty_inf.end_of_promotion
      end
      Spree::DataImportMailer::promotion_quantity_inflation_end(ord_qty_hash).deliver if qty_infs.present?
      
    rescue Exception => e   
    end
  end

  desc "Generate daily disputed cancelled orders report"
  task :generate_disputed_cancel_order_report => :environment do
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    disputed_cancelled_orders = []
    @orders = Spree::Order.where("cancel_on_fba=false AND is_cancel=true").order('order_date desc')
    if @orders.present?
      Spree::OrderMailer.disputed_cancel_orders(@orders).deliver
    end
  end

end
