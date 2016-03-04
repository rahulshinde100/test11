module Spree
  class Seller < ActiveRecord::Base
    attr_accessible :name, :address_1, :address_2, :city, :state, :zip, :country_id, :logo, :banner, :permalink, :business_type_id,
       :roc_number, :establishment_date, :url, :contact_person_name, :contact_person_email, :phone, :category_ids, :termsandconditions, :is_active, :user_id, :seller_user_ids, :comment, :deleted_at, :deactivated_at, :description

    validates_presence_of :name, :address_1, :city, :state, :country_id, :contact_person_name
    validates_format_of :contact_person_email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Invalid email"

    has_attached_file :logo, :styles => {
    :small => "50x100>",
    :medium => "100x200>",
    :large => "400x400>" },
    :default_url => "/assets/ship.li/logo.png"

    has_attached_file :banner, :styles => {
    :small => "100x100>",
    :medium => "300x300>",
    :large => "960x300>" },
    :default_url => "/assets/ship.li/banner.png"

    belongs_to  :country
    belongs_to  :type, :class_name => "Spree::BusinessType", :foreign_key => :business_type_id
    # belongs_to  :user
    has_many    :products, :dependent => :destroy
    has_many    :kits, :dependent => :destroy
    has_many    :stock_locations
    has_many    :stock_transfers
    has_many    :stores, :class_name => "Spree::StoreAddress", :dependent => :destroy
    has_many    :seller_categories, :dependent => :destroy
    has_many    :categories, :class_name => "Spree::Taxon", :through => :seller_categories
    has_many    :variants, through: :products

    # has_many    :seller_users, :dependent => :destroy
    # delegate   :store_users, :to => :seller_user
    # has_many   :store_users, :class_name => "Spree::User", :through => :seller_users
    # =========
    has_many :seller_users, :dependent => :destroy
    has_many :users, :through => :seller_users
    # =========
    has_many :seller_market_places, :dependent => :destroy
    has_many :market_places, :through => :seller_market_places
    # =========

    has_one     :bank_detail, :dependent => :destroy

    scope :is_active, where(:is_active => true, :deactivated_at => nil, :deleted_at => nil)
    scope :is_deactive, where(:is_active => false, :deleted_at => nil)
    scope :not_deleted, where(:deleted_at => nil)
    scope :deleted, where("deleted_at is not null")

    make_permalink order: :name

    def to_param
      permalink.present? ? permalink : (permalink_was || name.to_s.to_url)
    end

    def address
        address = [self.address_1, self.try(:address_2), "#{self.city} #{self.try(:state)},", "#{self.country.name} #{self.try(:zip)}"].compact
        address.delete("")
        address.join("<br/>")
    end

    # Commented this method - this method will give you the orders which has line items
    # def orders
    #   Spree::Order.includes(:line_items).where(:spree_line_items => {:variant_id => Spree::Variant.includes(:products).where(:product_id => self.products.map(&:id))})
    # end

    def orders_total
        Spree::LineItem.includes(:order).where("spree_orders.state ='complete' and variant_id = ?", Spree::Variant.where(:product_id => self.products.active.map(&:id)).map(&:id)).group("spree_orders.id").collect{|item| [item.price*item.quantity]}.sum
    end
  end
end
