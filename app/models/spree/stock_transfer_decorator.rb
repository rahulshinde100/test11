Spree::StockTransfer.class_eval do
  attr_accessible :received_date, :created_at, :updated_at, :number, :seller_id, :received_date, :damaged_quantity,
    :total_order_cost, :received_by, :expiry_date, :delivery_order, :purchase_order, :delivery_order_scan_copy

  has_attached_file :delivery_order_scan_copy


  #validates_presence_of :received_date, :received_quantity, :received_by, :if => self.source_location_id.nil?
  #validate :incoming_inventory

  def incoming_inventory
    puts "0.---------------------------#{source_location_id.inspect}"
    #unless source_location_id.nil?
      puts "1.---------------------------"
      errors.add( :received_date, 'Please provide received date') if (source_location_id.nil? && received_date.blank?)
      errors.add( :received_quantity, 'Please provide received quantity') if (source_location_id.nil? && received_quantity.blank?)
      errors.add( :received_by, 'Please provide received by') if (source_location_id.nil? && received_by.blank?)
      puts "2.---------------------------"
    #end
  end
end
