module Spree
    class BlockReview < ActiveRecord::Base
       attr_accessible :block_comment, :review_id
       belongs_to :review
    end
end
