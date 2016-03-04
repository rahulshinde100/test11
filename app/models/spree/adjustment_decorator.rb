Spree::Adjustment.class_eval do
    def set_eligibility
      result = self.mandatory || (self.amount != 0 && self.eligible_for_originator?)
      update_attribute_without_callbacks(:eligible, result)
      #Add this functionality as per ship.li requirment,
      turn_off_multiple_shipment_charges
    end


    #By default shipping charges will be added on every item
    #turn on only one shipping charge, and turn off rest of the shipping charges
    def turn_off_multiple_shipment_charges
      multiple_shipping_charges = self.adjustable.adjustments.where(:source_type => "Spree::Shipment")
      if multiple_shipping_charges.length > 1
        multiple_shipping_charges.each_with_index do |shipping_charges, index|
          next if index == 0
          shipping_charges.update_attribute_without_callbacks(:amount, 0)
          shipping_charges.update_attribute_without_callbacks(:eligible, false)
        end
      end
    end

    def is_free_shipping?(order)
      (order.adjustments.eligible.collect(&:originator) & Spree::Calculator::FreeShipping.all.collect(&:calculable)).include? self.originator
    end
end