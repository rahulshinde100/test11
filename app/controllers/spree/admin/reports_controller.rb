module Spree
  module Admin
    class ReportsController < Spree::Admin::BaseController
      respond_to :html
      before_filter :verify_seller, :except => [:index]
      # authorize_resource :class => false
      AVAILABLE_REPORTS = {
        :sales_total => { :name => Spree.t(:sales_total), :description => Spree.t(:sales_total_description) },
        :seller_wise_sale_total => {:name => Spree.t(:seller_wise_sale_total), :description => Spree.t(:seller_sales_total_description)}#,
        # :goods_and_services_tax => {:name => Spree.t(:goods_and_services_tax), :description => Spree.t(:goods_and_services_tax)}
      }

      def index
        @reports = AVAILABLE_REPORTS
        @sellers = Spree::Seller.where("is_active=true AND is_cm_user=true")
      end
      
      def load_form
        @sellers = Spree::Seller.where("is_active=true AND is_cm_user=true")
        file_name = nil
        case params[:type].to_i
          when 1
            # Weekly Report
            file_name = "weekly_report_form"
          when 2
            # Monthly Report
            file_name = "invocing_by_cart_report_form"
          when 3
            # Invocing Report by Cart Number
            file_name = "invocing_by_cart_report_form"  
        end      
        render :partial => file_name
      end
      
      def generate_report
        errors = nil
        file = nil
        seller = Spree::Seller.find(params[:seller][:id]) rescue nil
        start_date = params[:date][:start].to_date
        end_date = params[:date][:end].to_date
        errors = "Please select seller" if !seller.present?
        errors = "Start date always less than or equal to current date and end date" if (start_date > Time.now.to_date) || (start_date > end_date)
        if !errors.present?
          case params[:report_type].to_i
            when 1
            # Weekly Report
              file = seller.generate_weekly_sales_report(start_date, end_date)
            when 2
            # Monthly Report
            when 3
            # Invocing Report by Cart Number  
          end      
          if file.present?
            send_data(CustomJob.generate_excel_multi_worksheet_with_styling(file, []), :type => "application/ms-excel", :filename => "Weekly Sales Report "+seller.name+" "+start_date.to_s+" to "+end_date.to_s+".xls")
          else
            redirect_to :back, :notice => "Report is not available"  
          end  
        else
          redirect_to :back, :notice => errors
        end
      end
      
      def goods_and_services_tax
        #return
        @search = Order.complete.ransack(search_result)
        @orders = @search.result
        @orders = Kaminari.paginate_array(@search.result).page(params[:page]).per(100)
        @totals = gst_details(@orders)
        if @orders.present?
          heading = ['#','Order Id','Order Date','Payment Date','Payment Mode','Total Product Items', 'Sub Total (excl GST)','Sub Total (incl GST)','Discount Amount (excl GST)','Discount Amount (incl GST)','Delivery Charges (excl GST)','Delivery Charges (incl GST)','Paid Amount (excl GST)','Paid Amount (incl GST)','Total GST Paid']
          export_to_excel(@orders, @totals, heading, "goods_and_services_tax_from_#{@file_date}") if params[:frmt] == "xls"
          draw_pdf(@orders, @totals, heading, "goods_and_services_tax_from_#{@file_date}") if params[:frmt] == "pdf"
        end
      end
      
      def sales_total
        @search = Order.complete.ransack(search_result)
        @orders = @search.result
        @orders = Kaminari.paginate_array(@search.result).page(params[:page]).per(100)
        @totals = order_detail(@orders)
        if @orders.present?
          heading = ["#", "Order Number","Total Products","Order Subtotal","Shipping Charges","Discount","Order Total","GST (#{@tax.to_s}%)","Order Date","Customer Name","Payment Mode","Gift Order","Sample Product"]
          export_to_excel(@orders, @totals, heading, "sales_total_from_#{@file_date}") if params[:frmt] == "xls"
          draw_pdf(@orders, @totals, heading, "sales_total_from_#{@file_date}") if params[:frmt] == "pdf"
        end
      end

      def seller_wise_sale_total
        if spree_current_user.has_spree_role? 'admin'
           @sellers = Kaminari.paginate_array(Spree::Seller.is_active).page(params[:page]).per(100)
        else
          @sellers = Kaminari.paginate_array(Spree::Seller.where(:permalink => params[:permalink])).page(params[:page]).per(100)
        end
        @totals = {}
        @totals[:sellers_count] = 0
        @totals[:sellers_item_total] = 0
        @totals[:sellers_revenue_shared] = 0
        @totals[:sellers_net_revenue] = 0
        filter = search_result
        @sellers.each_with_index do | seller, index |
          if seller.orders.present? && seller.orders.complete.present?
            @search =  seller.orders.complete.ransack(filter)
            @orders = @search.result
            revenue_share = seller.revenue_share
            revenue_share_on_ware_house_sale = seller.revenue_share_on_ware_house_sale
            if @orders.present?
              line_items =[]
              @orders.collect{|order| [order.line_items.map(&:id)]}.each do |items|
                line_items << items
              end
              sale_items = Spree::LineItem.where(:id => line_items.flatten)
              item_total = sale_items.collect{|item| [item.price.to_f * item.quantity]}.flatten.sum
              revenue_shared = sale_items.collect{|item| [item.rcp.to_f * item.quantity]}.flatten.sum
              @totals[seller.permalink] = {
                :index => index + 1,
                :name => seller.name,
                :count => @orders.count,
                :item_total => item_total.round(2),
                :revenue_shared => revenue_shared.round(2),
                :net_revenue => (item_total - revenue_shared).round(2)
              }

              @totals[:sellers_count] += @totals[seller.permalink][:count]
              @totals[:sellers_item_total] += @totals[seller.permalink][:item_total]
              @totals[:sellers_revenue_shared] += @totals[seller.permalink][:revenue_shared]
              @totals[:sellers_net_revenue] += @totals[seller.permalink][:net_revenue]
            end
          end if @sellers.present?
        end
        if @totals.present?
          heading = ["#","Name","Count","Item Total","Revenue Shared","Net Revenue"]
          export_to_excel(@sellers, @totals, heading, "seller_wise_sale_total_from_#{@file_date}") if params[:frmt] == "xls"
          draw_pdf(@sellers, @totals, heading, "seller_wise_sale_total_from_#{@file_date}") if params[:frmt] == "pdf"
        end
      end

      def seller_detail_sale_total
        @seller = Spree::Seller.find_by_permalink(params[:permalink])
        @search = @seller.orders.ransack(search_result) if @seller.orders.complete.blank?
        if @seller.try(:orders).present? && @seller.orders.complete.present?
          @search = @seller.orders.complete.ransack(search_result)
          @orders = Kaminari.paginate_array(@search.result).page(params[:page]).per(100)
          @totals = order_detail(@orders)
          if @orders.present?
            heading = ["#","Order Number","Total Products","Order Subtotal","Shipping Charges","Discount","Order Total","GST (#{@tax.to_s}%)","Order Date","Customer Name","Payment Mode","Gift Order","Sample Product"]
            export_to_excel(@orders, @totals, heading, "details_sale_total_from_#{@file_date}") if params[:frmt] == "xls"
            draw_pdf(@orders, @totals, heading, "details_sale_total_from_#{@file_date}") if params[:frmt] == "pdf"
          end
        end
      end

      def authorize_admin
        authorize! params[:action].to_sym, :reports
      end

      private

      def verify_seller
        unless (spree_current_user.has_spree_role?("admin") || params[:permalink] == spree_current_user.seller.permalink)
          raise CanCan::AccessDenied do |exception|
            redirect_to root_url, :alert => "You are not authorise to access this page"
          end
        end
      end
      def search_result
        params[:q] = {} unless params[:q]

        if params[:q][:completed_at_gt].blank?
          params[:q][:completed_at_gt] = Time.zone.now.beginning_of_month
        else
          params[:q][:completed_at_gt] = Time.zone.parse(params[:q][:completed_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
        end

        if params[:q] && !params[:q][:completed_at_lt].blank?
          params[:q][:completed_at_lt] = Time.zone.parse(params[:q][:completed_at_lt]).end_of_day rescue ""
        else
          params[:q][:completed_at_lt] = Time.zone.now.end_of_day
        end
        if params[:q].delete(:completed_at_not_null) == "1"
          params[:q][:completed_at_not_null] = true
        else
          params[:q][:completed_at_not_null] = false
        end

        params[:q][:s] ||= "completed_at desc"
        @file_date = "#{params[:q][:completed_at_gt].to_date}"
        @file_date += "_to_#{params[:q][:completed_at_lt].to_date}" unless params[:q][:completed_at_lt].nil?
        search_result = params[:q]
      end

      def order_detail(orders)
        order_detail = {}
        @tax = Spree::TaxRate.first.try(:amount)
        orders.each_with_index do |order, index|
          discount = order.adjustments.eligible.collect{|ad| ad.amount if ad.amount < 0 && !ad.is_free_shipping?(order)}.flatten.compact.sum.to_f
          if spree_current_user.has_spree_role? 'admin'
            order_value = Spree::LineItem.where(:id => order.line_items.map(&:id)).collect{|item| [item.price * item.quantity]}.flatten.sum
          else
            order_value = Spree::LineItem.where(:id => order.line_items.map(&:id)).collect{|item| [item.rcp.to_f * item.quantity]}.flatten.sum
          end
          order_total = order_value + order.shipments.collect(&:cost).sum + discount
          shipping_charges_incl = order.is_free_shipping? ? 0 : order.shipments.collect(&:cost).sum
          order_detail[order.number] = {
            :index => index + 1,
            :order_number => order.number,
            :total_number_of_products => order.line_items.collect(&:quantity).sum,
            :order_value => order_value,
            :shipping_charges => shipping_charges_incl,
            :discount => discount.abs,
            :order_total => order_total,
            :taxes => (order_total * @tax).round(2),
            :order_date => order.completed_at.strftime("%d/%m/%Y"),
            :customer_name => order.ship_address.full_name,
            :payment_mode => order.payments.present? ? order.payments.first.payment_method.try(:name) : '',
            :gift_order => order.send_as_gift ? "True" : "False",
            :sample_product => 0
          }
        end if orders.present?
        order_detail
      end

      def gst_details(orders)
        gst_details = {}
        @tax = Spree::TaxRate.first.try(:amount)
        orders.each_with_index do |order, index|
          adjustment_incl = (order.adjustment_total >= 0 ? 0 : order.adjustments.collect(&:amount).sum).abs.round(2)
          shipping_charges_incl = order.is_free_shipping? ? 0 : order.shipments.collect(&:cost).sum
          paid_amount_incl = (order.item_total - adjustment_incl + shipping_charges_incl).round(2)
          gst_details[order.number] = {
            :index => index + 1,
            :order_number => order.number,
            :order_date => order.completed_at.strftime("%d/%m/%Y"),
            :payment_date => order.payments.present? ? order.payments.first.created_at.strftime("%d/%m/%Y") : '',
            :payment_mode => order.payments.present? ? order.payments.first.payment_method.try(:name) : '',
            :total_number_of_products => order.line_items.collect(&:quantity).sum,
            :sub_total_excl => (order.item_total * (1 - @tax)).round(2),
            :sub_total_incl => order.item_total.round(2),
            :discount_excl => (adjustment_incl * (1 - @tax)).round(2),
            :discount_incl => adjustment_incl.round(2),
            :shipping_charges_excl => (shipping_charges_incl * (1 - @tax)).round(2),
            :shipping_charges_incl => shipping_charges_incl.round(2),
            :paid_amount_excl => (paid_amount_incl - paid_amount_incl * @tax).round(2),
            :paid_amount_incl => paid_amount_incl.round(2),
            :total_gst_paid => (paid_amount_incl * @tax).to_f.round(2)
          }
        end if orders.present?
        gst_details
      end

      def export_to_excel(exce_rows, totals, heading, filename)
        sales_totals = Spreadsheet::Workbook.new
        sales_total = sales_totals.create_worksheet :name => 'sales_total'
        Spreadsheet::Excel::Internals::SEDOC_ROLOC.update(:light_blue => 0xc3d9f)
        Spreadsheet::Column.singleton_class::COLORS << :light_blue

        white = Spreadsheet::Format.new :color => 'black', :weight => 'bold', :size => 10, :align => 'center', :pattern_fg_color => :light_blue, :pattern => 1
        gray = Spreadsheet::Format.new :color => 'black', :weight => 'bold', :size => 10, :align => 'center', :pattern_fg_color => :white, :pattern => 1
        header_format = Spreadsheet::Format.new :color => 'white', :weight => 'bold', :size => 12, :align => 'center', :text_wrap => true, :pattern_fg_color => :black, :pattern => 1
        heading.each{ |v| sales_total.row(0).push v}
        index = 1
        exce_rows.each do | exce_row |
          if exce_row.class.name == "Spree::Seller"
            next if totals[exce_row.permalink].nil?
            totals[exce_row.permalink].each{ |k,v| sales_total.row(index).push v}
          else
            next if totals[exce_row.number].nil?
            totals[exce_row.number].each{ |k,v| sales_total.row(index).push v}
          end
          if index % 2 == 0
            sales_total.row(index).default_format = white
          else
            sales_total.row(index).default_format = gray
          end
          index += 1
        end if totals.present?

        if exce_rows.first.class.name == "Spree::Seller"
          sales_total.row(exce_rows.count + 1).push "","Total", totals[:sellers_count], totals[:sellers_item_total], totals[:sellers_revenue_shared], totals[:sellers_net_revenue]
        end
        sales_total.row(0).default_format = header_format
        blob = StringIO.new("")
        sales_totals.write blob
        #respond with blob object as a file
        send_data blob.string, :type => :xls, :filename => "#{filename}.xls"
        return
      end

      def draw_pdf(exce_rows, totals, heading, filename)
        require 'prawn'
        require 'prawn/core'
        require 'prawn/layout'
        body =[]
        if heading.length > 13
          col_width = {3 => 62,4 => 49,5 => 45,6 => 45,7 => 48,8 => 48,9 => 49,10 => 49,11 => 49,12 => 49,13 => 48,14 => 48,15 => 43}
        else
          col_width = {2 => 49,3 => 49,4 => 50,5 => 49,7 => 53,8 => 62,9 => 62}
        end
        exce_rows.each_with_index do | exce_row, index |
          row = []
          if exce_row.class.name == "Spree::Seller"
            next if totals[exce_row.permalink].nil?
            totals[exce_row.permalink].each{ |k,v| row << v}
          else
            next if totals[exce_row.number].nil?
            totals[exce_row.number].each{ |k,v| row << v}
          end
          body << row
        end
        if exce_rows.first.class.name == "Spree::Seller"
          row = []
           row << ""
           row << "Total"
           row << totals[:sellers_count]
           row << totals[:sellers_item_total]
           row << totals[:sellers_revenue_shared]
           row << totals[:sellers_net_revenue]
           body << row
           col_width = {5 => 49}
        end
        pdf = Prawn::Document.new(:page_layout => :landscape, :margin => [50,5,20])
        pdf.table body, :headers => heading, :font_size => 9, :row_colors => ["F2CBD8", "FFFFFF"], :position => :center, :column_widths => col_width do |table|
        end
        send_data pdf.render, :filename => "#{filename}.pdf", type: "application/pdf", disposition: "inline"
        return
      end
    end
  end
end
