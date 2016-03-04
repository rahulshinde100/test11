class Spree::Admin::BlockReviewsController < Spree::Admin::BaseController
    
    def new
        
    end

    def create
        @block_review = Spree::BlockReview.new(params[:block_reviews])
        @review = Spree::Review.find(params[:review_id])
        @block_review.update_attributes(:review_id => params[:review_id])
        @review.update_attributes(:approved => false)
        @block_review.save
        redirect_to admin_reviews_path
    end
end
