module Spree
  Activator.class_eval do
    cattr_accessor :event_names

    self.event_names = [
        'spree.order.contents_changed',
        'spree.set_special_price'
    ]

    def self.register_event_name(name)
      self.event_names << name
    end

    scope :event_name_starts_with, ->(name) { where('event_name LIKE ?', "#{name}%") }

    def self.active
      where('starts_at IS NULL OR starts_at < ?', Time.now).
          where('expires_at IS NULL OR expires_at > ?', Time.now)
    end

    def activate(payload)
    end

    def expired?
      starts_at && Time.now < starts_at || expires_at && Time.now > expires_at
    end
  end
end
