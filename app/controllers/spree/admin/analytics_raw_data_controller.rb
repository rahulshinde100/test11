require 'prawn'
#require 'prawn/core'
#require 'prawn/layout'
class Spree::Admin::AnalyticsRawDataController < Spree::Admin::BaseController
  
  def index
  	redirect_to abandoned_carts_admin_analytics_raw_data_path  	
  end
  
  def abandoned_carts
  	@search = Spree::Order.abandoned_orders.ransack(search_result)
    @orders = Kaminari.paginate_array(@search.result).page(params[:page]).per(100)
 
    if params[:frmt] == "xls" && @search.result.present?
    	@orders = @search.result
	  	orders = Spreadsheet::Workbook.new
	    search_term = orders.create_worksheet :name => 'sales_total'
	    Spreadsheet::Excel::Internals::SEDOC_ROLOC.update(:light_blue => 0xc3d9f)
	    Spreadsheet::Column.singleton_class::COLORS << :light_blue
	    white = Spreadsheet::Format.new :color => 'black', :weight => 'bold', :size => 10, :align => 'center', :pattern_fg_color => :light_blue, :pattern => 1
	    gray = Spreadsheet::Format.new :color => 'black', :weight => 'bold', :size => 10, :align => 'center', :pattern_fg_color => :white, :pattern => 1
	    header_format = Spreadsheet::Format.new :color => 'white', :weight => 'bold', :size => 12, :align => 'center', :text_wrap => true, :pattern_fg_color => :black, :pattern => 1

	    search_term.row(0).push "#","Order No", "User Name", "Customer Email", "Last Modified Date", "Total items in Cart", "Cart total value", "IP Address"
	    @orders.each_with_index do |order, index|
	    	search_term.row(index+1).push (index + 1), order.number, "#{order.try(:user).try(:firstname)} #{order.try(:user).try(:lastname)}", order.try(:user).try(:email), "#{order.created_at.strftime('%d %b %Y  %I:%M %p')}", order.line_items.sum(&:quantity), order.total, order.last_ip_address
	    end
	    search_term.row(0).default_format = header_format
	    blob = StringIO.new("")
      orders.write blob
      #respond with blob object as a file
      send_data blob.string, :type => :xls, :filename => "#{@filename}.xls" 
      return
	  end if @orders.present?

	  if params[:frmt] == "pdf" && @search.result.present?
	  	# col_width = {2 => 70, 3 => 50}
	  	@orders = @search.result
	  	body =[]
	  	heading = ["#","Order No", "User Name", "Customer Email", "Last Modified Date", "Total items in Cart", "Cart total value", "IP Address"]
	  	@orders.each_with_index do | order, index |
	  		row = []
	  		row << (index + 1)
	  		row << order.number
	  		row << "#{order.try(:user).try(:firstname)} #{order.try(:user).try(:lastname)}"
	  		row << order.try(:user).try(:email)
	  		row << "#{order.created_at.strftime('%d %b %Y  %I:%M %p')}"
	  		row << order.line_items.sum(&:quantity)
	  		row << order.total
	  		row << order.last_ip_address
	  		
	  		body << row
	  	end
	  	pdf = Prawn::Document.new(:page_layout => :landscape, :margin => [30,5,20])         
      pdf.table body, :headers => heading, :font_size => 9, :row_colors => ["F2CBD8", "FFFFFF"], :position => :center do |table|
      end 
      send_data pdf.render, :filename => "#{@filename}.pdf", type: "application/pdf", disposition: "inline"         
      return
		end if @orders.present?	  
  end

  def searched_terms
    @search = Spree::SearchTerm.ransack(search_result)
    @search_terms = Kaminari.paginate_array(@search.result.order("created_at DESC")).page(params[:page]).per(100)
    
    if params[:frmt] == "xls"
    	@search_terms = @search.result.order("created_at DESC")
	  	search_terms = Spreadsheet::Workbook.new
	    search_term = search_terms.create_worksheet :name => 'sales_total'
	    Spreadsheet::Excel::Internals::SEDOC_ROLOC.update(:light_blue => 0xc3d9f)
	    Spreadsheet::Column.singleton_class::COLORS << :light_blue
	    white = Spreadsheet::Format.new :color => 'black', :weight => 'bold', :size => 10, :align => 'center', :pattern_fg_color => :light_blue, :pattern => 1
	    gray = Spreadsheet::Format.new :color => 'black', :weight => 'bold', :size => 10, :align => 'center', :pattern_fg_color => :white, :pattern => 1
	    header_format = Spreadsheet::Format.new :color => 'white', :weight => 'bold', :size => 12, :align => 'center', :text_wrap => true, :pattern_fg_color => :black, :pattern => 1

	    search_term.row(0).push "#","Seach Term", "User", "Email", "Result Count", "Searched Date", "Searched Time"
	    @search_terms.each_with_index do |term, index|
	    	search_term.row(index+1).push (index + 1), term.search_term, term.user.try(:name), term.user.try(:email), term.result_count, "#{term.created_at.strftime('%d %b %Y')}", term.created_at.strftime("%I:%M %p")
	    end
	    search_term.row(0).default_format = header_format
	    blob = StringIO.new("")
      search_terms.write blob
      #respond with blob object as a file
      send_data blob.string, :type => :xls, :filename => "#{@filename}.xls" 
      return
	  end if @search_terms.present?

	  if params[:frmt] == "pdf"
	  	# col_width = {2 => 70, 3 => 50}
	  	@search_terms = @search.result.order("created_at DESC")
	  	body =[]
	  	heading = ["#","Seach Term", "User", "Email", "Result Count", "Searched Date", "Searched Time"]
	  	@search_terms.each_with_index do | term, index |
	  		row = []
	  		row << (index + 1)
	  		row << term.search_term
	  		row << term.user.try(:name)
	  		row << term.user.try(:email)
	  		row << term.result_count
	  		row << "#{term.created_at.strftime('%d %b %Y')}"
	  		row << term.created_at.strftime("%I:%M %p")
	  		body << row
	  	end
	  	pdf = Prawn::Document.new(:page_layout => :landscape, :margin => [30,5,20])         
      pdf.table body, :headers => heading, :font_size => 9, :row_colors => ["F2CBD8", "FFFFFF"], :column_widths => {1 => 250}, :position => :center do |table|
      end 
      send_data pdf.render, :filename => "#{@filename}.pdf", type: "application/pdf", disposition: "inline"         
      return
		end if @search_terms.present?	  	
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
