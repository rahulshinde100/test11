class Spree::SearchTerm < ActiveRecord::Base
  attr_accessible :result_count, :search_term, :user_id

  belongs_to :user, :class_name => 'Spree::User'
end
