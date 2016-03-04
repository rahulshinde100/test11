class CustomJob

  # Custom excel file generation
  def self.generate_excel(collections, heading, options={})
    message = ""
    xls_file = Spreadsheet::Workbook.new
    sheet = xls_file.create_worksheet :name => "Sheet 1"
    red = Spreadsheet::Format.new :color => 'black', :size => 10, :align => 'center', :pattern_fg_color => :red, :pattern => 1
    begin
      collections.each_with_index do |err, index|
        err.each do |r|
          #next unless r.present?
          sheet.row(index).push r
        end
      end
    rescue Exception => e
      message = e.message
    end
    blob = StringIO.new("")
    #blob = message if !message.present?
    xls_file.write blob
    blob.string
  end

  # Custom excel file generation multiple worksheets
  def self.generate_excel_multi_worksheet(collections, options={})
    message = ""
    xls_file = Spreadsheet::Workbook.new
    begin
      collections.each do |key, values|
        sheet = xls_file.create_worksheet :name => key
        red = Spreadsheet::Format.new :color => 'black', :size => 10, :align => 'center', :pattern_fg_color => :red, :pattern => 1
        values.each_with_index do |err, index|
          err.each do |r|
            #next unless r.present?
            sheet.row(index).push r
          end
        end
      end
    rescue Exception => e
      message = e.message
    end
    blob = StringIO.new("")
    #blob = message if !message.present?
    xls_file.write blob
    blob.string
  end

  # Custom excel file generation multiple worksheets
  def self.generate_excel_multi_worksheet_with_styling(collections, options={})
    message = ""
    xls_file = Spreadsheet::Workbook.new
    begin
      collections.each do |key, values|
        sheet = xls_file.create_worksheet :name => key
        red = Spreadsheet::Format.new :color => 'black', :size => 10, :align => 'center', :pattern_fg_color => :red, :pattern => 1
        values.each_with_index do |row_data, index|
=begin          
          if row_data[0][1].present?
            sheet.row(index).default_format = CustomJob.get_excel_styles("header1")
          else  
            sheet.row(index).default_format = CustomJob.get_excel_styles(nil)
          end
=end          
          row_data[0].each do |rd|
            sheet.row(index).push rd
          end
        end
      end
    rescue Exception => e
      message = e.message
    end
    blob = StringIO.new("")
    #blob = message if !message.present?
    xls_file.write blob
    blob.string
  end
  
  def self.get_excel_styles(style)
    case style
    when "header1"
      return Spreadsheet::Format.new :weight => :bold, :horizontal_align => :centre, :vertical_align => :centre, :size => 20
    when "header2"
      return Spreadsheet::Format.new :weight => :bold, :horizontal_align => :centre, :vertical_align => :centre, :size => 14
    when "header3"
      return Spreadsheet::Format.new :weight => :bold, :horizontal_align => :centre, :vertical_align => :centre, :size => 14
    when "footer1"
      return Spreadsheet::Format.new :weight => :bold, :horizontal_align => :centre, :vertical_align => :centre, :size => 14
    when "footer2"
      return Spreadsheet::Format.new :weight => :bold, :horizontal_align => :centre, :vertical_align => :centre, :size => 14
    when "footer3"
      return Spreadsheet::Format.new :weight => :bold, :horizontal_align => :centre, :vertical_align => :centre, :size => 14
    when "row1"
      return Spreadsheet::Format.new :weight => :bold, :horizontal_align => :centre, :vertical_align => :centre, :size => 14
    when "row2"
      return Spreadsheet::Format.new :weight => :bold, :horizontal_align => :centre, :vertical_align => :centre, :size => 14
    when "row3"        
      return Spreadsheet::Format.new :weight => :bold, :horizontal_align => :centre, :vertical_align => :centre, :size => 14
    else    
      return Spreadsheet::Format.new :weight => :bold, :horizontal_align => :centre, :vertical_align => :centre, :size => 14
    end  
  end

  
end