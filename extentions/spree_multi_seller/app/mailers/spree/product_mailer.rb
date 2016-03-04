class Spree::ProductMailer < ActionMailer::Base
  default from: "business@ship.li"
  def reject(product)
  	@product = product
  	@subject = "Product is Reject"
	mail(:to => product.seller.contact_person_email, :subject => @subject)
  end

  def approve(product)
  	@product = product
  	@subject = "Product #{product.name} is Approved"
  	mail(:to => product.seller.contact_person_email, :subject => @subject)
  end

  def create_product(product)
    @product = product
    @subject = "Product #{product.name} is Created"
    mail(:to => product.seller.contact_person_email, :subject => @subject)
  end
end
