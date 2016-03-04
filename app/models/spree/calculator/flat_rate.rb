require_dependency 'spree/calculator'

module Spree
  class Calculator::FlatRate < Calculator
    preference :amount, :decimal, :default => 0
    preference :currency, :string, :default => Spree::Config[:currency]

    attr_accessible :preferred_amount, :preferred_currency

    def self.description
      Spree.t(:flat_rate_per_order)
    end

    def compute(object=nil)
      refer = Mbsy::Ambassador.find(:email => "#{object.try(:email)}")
      ambassador_promo = Spree::Promotion.find_by_name("ambassador")
      if refer["ambassador"]["balance_money"].to_i < 10 && self.calculable.promotion.code == ambassador_promo.try(:first).try(:code)
        return nil
      end
      self.preferred_amount
    end
  end
end