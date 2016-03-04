module Spree
  class Image < Asset
    validates_attachment_presence :attachment
    validate :no_attachment_errors

    attr_accessible :alt, :attachment, :position, :viewable_type, :viewable_id
    validates_format_of :attachment, :with => %r{\.(png|jpg|jpeg|gif|)$}i, :message => "must be in png, jpg, jpeg and gif format"
    has_attached_file :attachment,
                      styles: { mini: '48x48>', small: '100x100>', product: '240x240>', large: '600x600>' },
                      default_style: :product,
                      url: '/spree/products/:id/:style/:basename.:extension',
                      path: ':rails_root/public/spree/products/:id/:style/:basename.:extension',
                      convert_options: { all: '-strip -auto-orient -colorspace sRGB' }
    # save the w,h of the original image (from which others can be calculated)
    # we need to look at the write-queue for images which have not been saved yet
    after_post_process :find_dimensions
    after_update :check_updated_fields
    after_create :insert_for_mp

    def insert_for_mp
      p self
      if self.viewable_type.present?
        variant = Spree::Variant.find(self.viewable_id) rescue nil
        product = variant.product
        market_places = product.market_places
        if variant.is_master
          @variants =[]
          @variants << (product.variants.present? ? product.variants : product.master)# product.variants
          @variants = @variants.flatten
          #variants =  Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%new_image%'").where(:product_id => product.id, :variant_id => @variants.map(&:id))
          #if !variants.present?
          market_places.each do |market_place|
            p market_place
            @market_place_product = Spree::SellersMarketPlacesProduct.where(:product_id => product.id,:seller_id => product.seller_id, :market_place_id => market_place.id)
            if @market_place_product.present?
              desc = 'new_image'#ProductJob.get_updated_fields(['new_image'],market_place.code)
              @variants.each do |v|
                Spree::RecentMarketPlaceChange.create!(:variant_id => v.id,:product_id => product.id,:seller_id => product.seller_id, :market_place_id => market_place.id, :description => desc, :update_on_fba=>false)
              end

            end
          end
          #end
        else
          #variants =  Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%new_image%'").where(:product_id => product.id, :variant_id => variant.id)
          #if !variants.present?
          market_places.each do |market_place|
            @market_place_product = Spree::SellersMarketPlacesProduct.where(:product_id => product.id,:seller_id => product.seller_id, :market_place_id => market_place.id)
            if @market_place_product.present?
              desc = 'new_image'#ProductJob.get_updated_fields(['new_image'],market_place.code)
              #variant.each do |v|
              Spree::RecentMarketPlaceChange.create!(:variant_id => variant.id,:product_id => product.id,:seller_id => product.seller_id, :market_place_id => market_place.id, :description => desc, :update_on_fba=>false)
              #end
            end
          end
          #end
        end
      end

    end

    def check_updated_fields
      if self.viewable_type.present?
        variant = Spree::Variant.find(self.viewable_id)
        product = variant.product
        market_places = product.market_places

        if variant.is_master
          @variants = []
          @variants << (product.variants.present? ? product.variants : product.master)# product.variants
          @variants = @variants.flatten
          #variants =  Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%new_image%'").where(:product_id => product.id, :variant_id => @variants.map(&:id))

          #if !variants.present?
          market_places.each do |market_place|
            @market_place_product = Spree::SellersMarketPlacesProduct.where(:product_id => product.id,:seller_id => product.seller_id, :market_place_id => market_place.id)
            desc = !new_record? ? ProductJob.get_updated_fields(self.changed,market_place.code) : ProductJob.get_updated_fields(['new_image'],market_place.code)
            if @market_place_product.present?
              @variants.each do |v|
                Spree::RecentMarketPlaceChange.create!(:variant_id => v.id,:product_id => product.id,:seller_id => product.seller_id, :market_place_id => market_place.id, :description => desc.join(','), :update_on_fba=>false)
              end
            end
          end
          #end
        else
          variants =  Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%new_image%'").where(:product_id => product.id, :variant_id => variant.id)
          if !variants.present?
            market_places.each do |market_place|
              @market_place_product = Spree::SellersMarketPlacesProduct.where(:product_id => product.id,:seller_id => product.seller_id, :market_place_id => market_place.id)
              desc = !new_record? ? ProductJob.get_updated_fields(self.changed,market_place.code) : ProductJob.get_updated_fields(['new_image'],market_place.code)
              if @market_place_product.present?
                Spree::RecentMarketPlaceChange.create!(:variant_id => variant.id,:product_id => product.id,:seller_id => product.seller_id, :market_place_id => market_place.id, :description => desc.join(','), :update_on_fba=>false)
              end
            end
          end
        end
      end

    end

    include Spree::Core::S3Support
    supports_s3 :attachment

    Spree::Image.attachment_definitions[:attachment][:styles] = ActiveSupport::JSON.decode(Spree::Config[:attachment_styles]).symbolize_keys!
    Spree::Image.attachment_definitions[:attachment][:path] = Spree::Config[:attachment_path]
    Spree::Image.attachment_definitions[:attachment][:url] = Spree::Config[:attachment_url]
    Spree::Image.attachment_definitions[:attachment][:default_url] = Spree::Config[:attachment_default_url]
    Spree::Image.attachment_definitions[:attachment][:default_style] = Spree::Config[:attachment_default_style]

    #used by admin products autocomplete
    def mini_url
      attachment.url(:mini, false)
    end

    def find_dimensions
      temporary = attachment.queued_for_write[:original]
      filename = temporary.path unless temporary.nil?
      filename = attachment.path if filename.blank?
      geometry = Paperclip::Geometry.from_file(filename)
      self.attachment_width  = geometry.width
      self.attachment_height = geometry.height
    end

    # if there are errors from the plugin, then add a more meaningful message
    def no_attachment_errors
      unless attachment.errors.empty?
        # uncomment this to get rid of the less-than-useful interrim messages
        # errors.clear
        errors.add :attachment, "Paperclip returned errors for file '#{attachment_file_name}' - check ImageMagick installation or image source file."
        false
      end
    end
  end
end