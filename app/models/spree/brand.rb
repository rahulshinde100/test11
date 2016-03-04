class Spree::Brand < ActiveRecord::Base
  attr_accessible :name, :description, :logo, :banner, :permalink

  validates :name, :uniqueness => {:case_sensitive => false}, :presence => true
  validates :permalink, :uniqueness => {:case_sensitive => false}, :presence => true

  has_attached_file :logo, :styles => { :small => "50x100>", :medium => "100x200>", :large => "400x400>" }
  has_attached_file :banner, :styles => { :small => "100x100>", :medium => "300x300>", :large => "960x300>" }

  has_many :products

  make_permalink order: :name

  def to_param
	  permalink.present? ? permalink : (permalink_was || name.to_s.to_url)
	end
end
