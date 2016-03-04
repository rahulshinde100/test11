require 'csv'
require 'whenever'
require "#{Rails.root}/app/helpers/application_helper"
require "#{Rails.root}/app/jobs/promotion_job"
include ApplicationHelper

namespace :promotions do
  desc "Run a discount promotion and update special price on MP"
  task :start_discount_promotion => :environment do
    start_date = Time.zone.now.beginning_of_day
    end_date = start_date + 1.hour
    promotions = Spree::Promotion.includes(:promotion_actions).where(:event_name => 'spree.set_special_price', :starts_at => start_date).where("expires_at > ?", start_date)
    promotions.each do |promotion|
      PromotionJob.start_promotion(promotion,'start')
    end
  end
  task :close_discount_promotion => :environment do
    start_date = Time.zone.now.end_of_day
    promotions = Spree::Promotion.includes(:promotion_actions).where(:event_name => 'spree.set_special_price', :expires_at  => start_date)
    promotions.each do |promotion|
      PromotionJob.start_promotion(promotion,'end')
    end
  end
end