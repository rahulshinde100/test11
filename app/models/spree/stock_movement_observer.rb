class Spree::StockMovementObserver < ActiveRecord::Observer
	observe Spree::StockMovement

	def after_create(stock_movement)
		notifications = stock_movement.stock_item.variant.notifications
		notifications.each do |notification|
			Spree::ProductNotificationMailer.notify_me(notification).deliver
		end if stock_movement.stock_item.in_stock? && notifications.present?
		notifications.destroy_all
	end
end
