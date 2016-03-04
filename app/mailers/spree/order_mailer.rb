module Spree
  class OrderMailer < BaseMailer
  	def confirm_email(order, resend = false)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      @subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      @subject += "Order Confirmation ##{@order.number}"
      mail(to: @order.email, from: from_address, subject: @subject)
    end

    def seller_order_delivery(order, line_items, seller)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      @line_items = line_items
      @seller = seller
      @subject = "Order Confirmation ##{@order.number}"
      mail(to: seller.contact_person_email, from: "no-reply@channel-manager.com", subject: @subject)
    end

    def seller_order_pickup(order, line_items, seller)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      @line_items = line_items
      @seller = seller
      @subject = "Order Confirmation ##{@order.number}"
      mail(to: seller.contact_person_email, from: "no-reply@channel-manager.com", subject: @subject)
    end

    def seller_order_mix(order, line_items, seller)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      @line_items = line_items
      @seller = seller
      @subject = "Order Confirmation ##{@order.number}"
      mail(to: seller.contact_person_email, from: "no-reply@channel-manager.com", subject: @subject)
    end

    def cancel_email(order, resend = false)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      @subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      @subject += "#{Spree::Config[:site_name]} #{Spree.t('order_mailer.cancel_email.subject')} ##{@order.number}"
      mail(to: @order.email, from: from_address, subject: @subject)
    end

    def pick_up_at_store(item, order)
      @subject = "Order Pick Up at Store ##{order.number}"
      @item = item
      @items = order.line_items.where(:stock_location_id => item.stock_location.id)
      @order = order
      mail(to: item.stock_location.email, from: "no-reply@channel-manager.com", subject: @subject)
    end

    def pick_up_at_store_user(order,store)
      @order = order
      @store = store
      @subject = "Order Pick Up at Store ##{order.number}"
      mail(to: @order.email, from: "no-reply@channel-manager.com", subject: @subject)
    end

    def pick_up_at_store_seller(order,store)
      @order = order
      @store = store
      @subject = "Order Pick Up at Store ##{order.number}"
      mail(to: store.seller.contact_person_email, from: "no-reply@channel-manager.com", subject: @subject)
    end

    # Mail for not cancelled orders on FBA due to order go thru delivery
    def order_not_cancelled_notification(orders)
      @orders = orders
      #@emails = ["abhijeet.ghude@anchanto.com", "milind.phirake@anchanto.com", "michael.ang@anchanto.com", "ritika.shetty@anchanto.com", "swapnil.gadewar@anchanto.com", "cecile.courbon@anchanto.com", "rayson.mahindran@anchanto.com", "saravanan.thambiyyan@anchanto.com"]
      @subject = "Channel Manager : URGENT | Orders Not Cancelled on FBA"
      #mail(to: "abhimanyu.kashikar@anchanto.com", cc: @emails, bcc: "nitin.khairnar@anchanto.com", from: "no-reply@channel-manager.com", subject: @subject)
      mail(to: "abhijeet.ghude@anchanto.com", bcc: "nitin.khairnar@anchanto.com", from: "no-reply@channel-manager.com", subject: @subject)
    end

    # Mail for not cancelled order item on FBA due to order go thru delivery
    def order_item_not_cancelled_notification(order, reason)
      @order = order
      @reason = reason
      #@emails = ["abhijeet.ghude@anchanto.com", "milind.phirake@anchanto.com", "michael.ang@anchanto.com", "ritika.shetty@anchanto.com", "swapnil.gadewar@anchanto.com", "cecile.courbon@anchanto.com", "rayson.mahindran@anchanto.com", "saravanan.thambiyyan@anchanto.com"]
      @subject = "Channel Manager : URGENT | Order #{order.cart_no.to_s} Not Cancelled on FBA"
      #mail(to: "abhimanyu.kashikar@anchanto.com", cc: @emails, bcc: "nitin.khairnar@anchanto.com", from: "no-reply@channel-manager.com", subject: @subject)
      mail(to: "abhijeet.ghude@anchanto.com", bcc: "nitin.khairnar@anchanto.com", from: "no-reply@channel-manager.com", subject: @subject)
    end

    # Mail for not update state in FBA order list
    def order_state_not_changed_notification(orders, errors)
      @errors = errors
      @emails = ["milind.phirake@anchanto.com"]
      @subject = "Channel Manager : URGENT | Order State Not Updated in FBA"
      @orders = orders
      mail(to: "abhijeet.ghude@anchanto.com", cc: @emails, bcc: "nitin.khairnar@anchanto.com", from: "no-reply@channel-manager.com", subject: @subject)
    end

    def order_bypass_notification(order, email, subject)
      @order = order
      @seller = @order.seller
      @email = email
      @subject = subject
      mail(to: @email, bcc: 'abhijeet.ghude@anchanto.com', from: "no-reply@channel-manager.com", subject: @subject)
    end

    def duplicate_order_on_fba(order, subject)
      @order = order
      @seller = @order.seller
      @subject = subject
      if Rails.env.eql?('production')
        mail(to: 'abhimanyu.kashikar@anchanto.com', cc: 'abhijeet.ghude@anchanto.com',bcc: "nitin.khairnar@anchanto.com", from: "no-reply@channel-manager.com", subject: @subject)
      else
        mail(to: 'pooja.dudhatra@anchanto.com', from: "no-reply@channel-manager.com", subject: @subject)
      end


    end

    def disputed_cancel_orders(orders)
      @orders = orders
      @subject = "Channel Manager | Orders Not Cancelled on FBA"
      if Rails.env.eql?('production')
        @emails = ["abhijeet.ghude@anchanto.com", "milind.phirake@anchanto.com", "michael.ang@anchanto.com", "ritika.shetty@anchanto.com", "swapnil.gadewar@anchanto.com", "cecile.courbon@anchanto.com", "rayson.mahindran@anchanto.com", "saravanan.thambiyyan@anchanto.com"]
        mail(to: "abhimanyu.kashikar@anchanto.com", cc: @emails, bcc: "nitin.khairnar@anchanto.com", from: "no-reply@channel-manager.com", subject: @subject)
      elsif Rails.env.eql?('development')
        @cc = []
        @to = ["pooja.dudhatra@anchanto.com"]
        mail(to: "pooja.dudhatra@anchanto.com", cc: @cc, from: "no-reply@channel-manager.com", subject: @subject)
      else
        @cc = ["abhijeet.ghude@anchanto.com", "nitin.khairnar@anchanto.com"]
        @to = ["gajanan.deshpande@anchanto.com"]
        mail(to: @to, cc: @cc, bcc: "pooja.dudhatra@anchanto.com", from: "no-reply@channel-manager.com", subject: @subject)
      end
    end
  end
end
