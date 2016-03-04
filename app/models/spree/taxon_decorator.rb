Spree::Taxon.class_eval do
	attr_accessible :sequence
  default_scope :order => 'name ASC'
  scope :main_taxons, lambda{Spree::Taxonomy.categories.taxons.unscoped.order(:sequence).collect{|taxon| taxon if taxon.parent.nil? || taxon.parent.parent.nil?}.compact}
  has_attached_file :icon,
      styles: { mini: '32x32>', normal: '128x128>' },
      default_style: :mini,
      url: '/images/taxons/:id/:style/:basename.:extension',
      path: '/images/taxons/:id/:style/:basename.:extension',
      default_url: '/assets/default_taxon.png'

	# validates_ :sequence

    has_many :taxons_market_places, :dependent => :destroy
    has_many :market_places, :through => :taxons_market_places

  # Load user defined paperclip settings
  if Spree::Config[:use_s3]
    s3_creds = { :access_key_id => Spree::Config[:s3_access_key], :secret_access_key => Spree::Config[:s3_secret], :bucket => Spree::Config[:s3_bucket] }
    Spree::Taxon.attachment_definitions[:icon][:storage] = :s3
    Spree::Taxon.attachment_definitions[:icon][:s3_credentials] = s3_creds
    Spree::Taxon.attachment_definitions[:icon][:s3_headers] = ActiveSupport::JSON.decode(Spree::Config[:s3_headers])
    Spree::Taxon.attachment_definitions[:icon][:bucket] = Spree::Config[:s3_bucket]
    Spree::Taxon.attachment_definitions[:icon][:s3_protocol] = Spree::Config[:s3_protocol].downcase unless Spree::Config[:s3_protocol].blank?
    Spree::Taxon.attachment_definitions[:icon][:s3_host_alias] = Spree::Config[:s3_host_alias]
    Spree::Taxon.attachment_definitions[:icon][:url] = Spree::Config[:attachment_url]
  end

  scope :last_updated , lambda { |last_date| where("updated_at >= ?", last_date.to_date.beginning_of_day) }

	def product_available(id)
		return self.products.active.where(:seller_id => id).count == 0 ? false : true
	end

	def product_count(id)
		self.products.active.where(:seller_id => id).count
	end

  def get_parent_taxon
    ar = self.permalink.split("/")
    ar = ar[0..1].join("/")
    Spree::Taxon.find_by_permalink(ar).name
  end

  def get_parent
    ar = self.permalink.split("/")
    ar = ar[0..1].join("/")
    Spree::Taxon.find_by_permalink(ar)
  end

  def get_taxon_permalink
    ar = self.permalink.split("/")
    ar = ar[1]
  end

end
