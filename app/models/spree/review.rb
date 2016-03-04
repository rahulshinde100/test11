class Spree::Review < ActiveRecord::Base
  belongs_to :product
  belongs_to :user, :class_name => Spree.user_class.to_s
  has_many   :feedback_reviews
  has_one    :block_review  

  after_save :recalculate_product_rating, :if => :approved?
  after_destroy :recalculate_product_rating

  validates_numericality_of :rating, :only_integer => true

  default_scope order("spree_reviews.created_at DESC")
  
  scope :localized, lambda { |lc| where('spree_reviews.locale = ?', lc) }

  attr_protected :user_id, :product_id, :ip_address
  attr_accessible :approved , :product, :review, :rating

  def blocked?
    if self.block_review.present?
        return true
    else
        return false
    end
  end

  class << self
    def approved
      where(:approved => true)
    end

    def not_approved
      where(:approved => false)
    end

    def approval_filter
      where(["(? = ?) or (approved = ?)", false , true, true])
    end

    # returns self aprroved and unapproved and others approved
    def self_unapproved(current_user,product)
         product.reviews.collect{|r| r if r.user_id == current_user.id || r.approved}.reject(&:blank?)
    end

    def oldest_first
      order("created_at asc")
    end

    def preview
      limit(Spree::Reviews::Config[:preview_size]).oldest_first
    end
  end

  def feedback_stars
    return 0 if feedback_reviews.size <= 0
    ((feedback_reviews.sum(:rating) / feedback_reviews.size) + 0.5).floor
  end

  def recalculate_product_rating
    reviews_count = product.reviews.reload.approved.count

    if reviews_count > 0
      product.avg_rating = product.reviews.approved.sum(:rating).to_f / reviews_count
      product.reviews_count = reviews_count
      product.save
    else
      product.update_attribute(:avg_rating, 0)
    end
  end
end
