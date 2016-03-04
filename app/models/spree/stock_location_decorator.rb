module Spree
  StockLocation.class_eval do
  	has_many :line_items, :dependent => :destroy
    has_many :stock_location_holiday_lists
    has_many :holiday_lists, :class_name => "Spree::HolidayList", :through => :stock_location_holiday_lists

#
  def backorderable_default
    true
  end

  scope :last_updated , lambda { |last_date| where("updated_at >= ?", last_date.to_date.beginning_of_day) }

#    def possible_pickup_dates
  def possible_pickup_dates
    delivery_date = []
    cross_time = Time.parse("#{Date.today} 9:59:59")

    until delivery_date.length == 3
      if Time.now < cross_time
        cross_time = cross_time
      else
        cross_time = cross_time + 1*86400
      end
      until is_holiday(cross_time) == false
        cross_time = cross_time + 1*86400 #possible cross date
      end

      order_date = Time.now
      if order_date < cross_time
        order_date = cross_time #+ 1*86400
      else
        order_date = cross_time + 1*86400
      end
      until is_holiday(order_date) == false
        order_date = order_date + 1*86400 #process date
      end

      delivery_date << with_format(order_date)
      cross_time = cross_time + 1*86400
    end
    delivery_date
  end

  def is_holiday(date)
    seller_off = []

    holiday_lists.each do |holiday|
      if holiday.to.nil?
        seller_off.push(holiday.to)
      else
        seller_off.push(get_date_ranges(holiday.from, holiday.to))
      end
    end
    seller_off = seller_off.flatten
    seller_off.compact!
    seller_off.sort!

    #seller_off = get_date_ranges(seller_off.first, seller_off.last)
    #ap seller_off

    #disable weekends
    #if date.wday == 0 || date.wday == 6 || seller_off.include?(date.to_date) #collect date object from this method
    if seller_off.include?(date.to_date)
      return true
    else
      return false
    end
  end

    def get_date_ranges(from, to)
      (from..to).map{ |date| date }
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

    def location_address
      address = ["#{self.name}", self.address1, self.address2, "#{self.country} #{self.zipcode}"].compact
    address.delete("")
    address.join("<br/>")
    end

  end
end