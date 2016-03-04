Spree::Prototype.class_eval do
	scope :last_updated , lambda { |last_date| where("updated_at >= ?", last_date.to_date.beginning_of_day) }
end