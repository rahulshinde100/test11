Spree::Promotion.class_eval do
  after_update :check_for_close, :check_for_start

  scope :on_going_promotions, lambda { where("expires_at >= ? ", Time.now)}

  # after_create

  # def activate(payload)
  #   return unless order_activatable? payload[:order] if payload[:order].present?
  #
  #   # make sure code is always downcased (old databases might have mixed case codes)
  #   if code.present?
  #     event_code = payload[:coupon_code]
  #     return unless event_code == self.code.downcase.strip
  #   end
  #
  #   if path.present?
  #     return unless path == payload[:path]
  #   end
  #
  #   actions.each do |action|
  #     action.perform(payload)
  #   end
  # end

  # def usage_limit_exceeded?(order = nil)
  #   usage_limit.present? && usage_limit > 0 #&& adjusted_credits_count(order) >= usage_limit
  # end
  def check_for_close
    if self.event_name == 'spree.set_special_price'
      current_date = Time.zone.now
      if self.promotion_rules.present?
        if self.changed.include? 'expires_at'
          if self.expires_at < current_date
            PromotionJob.start_promotion(self,'close') if self.promotion_actions.where(:type =>'Spree::Promotion::Actions::Discount').present?
          end
          if self.expires_at > current_date && self.starts_at < current_date
            PromotionJob.start_promotion(self,'start')  if self.promotion_actions.where(:type =>'Spree::Promotion::Actions::Discount').present?
          end
        end
        if self.changed.include? 'starts_at'
          if self.starts_at < current_date
            PromotionJob.start_promotion(self,'start')  if self.promotion_actions.where(:type =>'Spree::Promotion::Actions::Discount').present?
          end
        end
      end
    end
  end
def check_for_start
  if self.event_name == 'spree.set_special_price'
    current_date = Time.zone.now
    if (self.starts_at < current_date && self.expires_at > current_date) && (self.promotion_actions.present? && self.promotion_rules.present?)
      PromotionJob.start_promotion(self,'start') if self.promotion_actions.where(:type =>'Spree::Promotion::Actions::Discount').present?
    end
  end
end
  def sellers
    @sellers ||= self.rules.all.inject([]) do |sellers, rule|
      rule.respond_to?(:sellers) ? sellers << rule.sellers : sellers
    end.flatten.uniq
  end
  def taxons
    @taxons ||= self.rules.all.inject([]) do |taxons, rule|
      rule.respond_to?(:taxons) ? taxons << rule.taxons : taxons
    end.flatten.uniq
  end
  def market_places
    @market_places ||= self.rules.all.inject([]) do |market_places, rule|
      rule.respond_to?(:market_places) ? market_places << rule.market_places : market_places
    end.flatten.uniq
  end

  def variants
    @variants ||= self.rules.all.inject([]) do |variants, rule|
      rule.respond_to?(:variants) ? variants << rule.variants : variants
    end.flatten.uniq
  end
  def is_active_promotion
    (self.starts_at < Time.zone.now && self.expires_at > Time.zone.now)
  end
end