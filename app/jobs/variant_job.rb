class VariantJob
  require 'archive/zip'
  require 'spreadsheet'

  def self.create_products_on_fba(variants_ids, current_user,action_on_fba)
    send_invoice_path = FULFLMNT_PATH+"/inventory/product/create"
    send_invoice_path = FULFLMNT_PATH+"/inventory/product/update" if action_on_fba == 'updating'
    error_hash = []
    error_hash << ['SKU','Name', 'UPC', 'Width','Height','Depth','Weight','Cost Price','','','Please Find the errors Below']
    variants_ids.each do |id|
      variant = Spree::Variant.find(id)
      product = variant.product
      seller = variant.product.seller
      smps = seller.seller_market_places.where(:is_active=>true) if seller.present?
      fba_api_key = smps.first.fba_api_key if smps.present?
      if fba_api_key.present? &&  smps.first.fba_signature.present?
        authorization = Base64.encode64("#{USER}:#{PASSWORD}")
        contact_person_email = variant.product.seller.contact_person_email.present? ? variant.product.seller.contact_person_email : nil
        image = Spree::Asset.where('type in (?) and viewable_id = ?',['Spree::Image'],variant.id).first
        #fba_api_key = '3b750a08e78242133269168aa1b51b1d25fc19334d1234'
        image_url = ''
        image_url = image.attachment.url(:original) if image_url.present?
        name = (product.variants.present? ? (variant.name+"-"+variant.option_values.first.presentation.to_s) : variant.name)
        resp_body = RestClient.post(send_invoice_path, {:api_key =>fba_api_key, :version =>"2.0", :signature=>smps.first.fba_signature.strip, :email=>contact_person_email.strip, :product =>{:name => name, :sku => variant.sku, :mfupc_code => variant.upc || '', :width => variant.width, :height => variant.height, :length => variant.depth, :weight => variant.weight, :cost_price => variant.cost_price, :image_url => image_url  }}, {:Authorization => authorization})
        resp = JSON.parse(resp_body)
        if resp["response"] == "failure"
          error_hash << [variant.sku, variant.product.name, variant.upc,variant.width, variant.height, variant.depth, variant.weight, variant.cost_price , '' ,'' , resp["message"]]
          if resp["message"].include? 'Sku has already been taken'
            variant.update_attributes(:is_created_on_fba => true)
          else
            variant.update_attributes(:is_created_on_fba => false)  if action_on_fba == 'creating'
            variant.update_attributes(:updated_on_fba => true) if action_on_fba == 'updating'
          end
          # Spree::OmsLog.create!(:p => order.id, :server_error_log => resp["message"])
        else
          variant.update_attributes(:is_created_on_fba => true) if action_on_fba == 'creating'
          variant.update_attributes(:updated_on_fba => true) if action_on_fba == 'updating'
          variant.recent_market_place_changes.where(:update_on_fba=>true).update_all(:deleted_at => Date.today)
          #variant.recent_market_place_changes.where(:update_on_fba=>true).destroy_all #if variant.recent_market_place_changes.present?
          # Spree::OmsLog.create!(:order_id => order.id, :oms_reference_number => resp["reference_id"], :oms_api_responce => resp["response"], :oms_api_message => resp["message"])
        end
      end
    end
    if error_hash.present? && error_hash.size >= 2
      message = "You have some errors in #{action_on_fba} products on FBA, for details PFA. Rest of the products are processed successfully"
      subject = "[Channel Manager] Status for Create/Update Products on FBA"
      file = ImportJob.generate_excel(error_hash)
      Spree::ProductNotificationMailer::fail_on_fba(current_user.try(:email), subject, message, file, "Product_error_on_FBA_#{Date.today.strftime('%d-%m-%Y')}.xls").deliver
    else
      message = "All the products are processed successfully on FBA"
      subject = "[Channel Manager] Status for Create/Update Products on FBA"

      Spree::ProductNotificationMailer::fail_on_fba(current_user.try(:email), subject, message, '', '' ).deliver
    end
  end

  def self.update_product_on_fba(variants, current_user)
    send_invoice_path = FULFLMNT_PATH+"/inventory/product/update"
    error_hash = []
    error_hash << ['SKU','Name', 'UPC', 'Width','Height','Depth','Weight','Cost Price','','','Please Find the errors Below']
    variants.each do |variant|
      product = variant.product
      seller = variant.product.seller
      smps = seller.seller_market_places.where(:is_active=>true) if seller.present?
      fba_api_key = smps.first.fba_api_key if smps.present?
      if fba_api_key.present? &&  smps.first.fba_signature.present?
        authorization = Base64.encode64("#{USER}:#{PASSWORD}")
        contact_person_email = variant.product.seller.contact_person_email.present? ? variant.product.seller.contact_person_email : nil
        image = Spree::Asset.where('type in (?) and viewable_id = ?',['Spree::Image'],variant.id).first
        #fba_api_key = '3b750a08e78242133269168aa1b51b1d25fc19334d1234'
        image_url = ''
        image_url = image.attachment.url(:original) if image_url.present?
        name = (product.variants.present? ? (variant.name+"-"+variant.option_values.first.presentation.to_s) : variant.name)
        resp_body = RestClient.post(send_invoice_path, {:api_key =>fba_api_key, :version =>"2.0", :signature=>smps.first.fba_signature.strip, :email=>contact_person_email.strip, :product =>{:name => name, :sku => variant.sku, :product_code => variant.upc || '', :width => variant.width, :height => variant.height, :length => variant.depth, :weight => variant.weight, :cost_price => variant.cost_price, :image_url => image_url  }}, {:Authorization => authorization})
        resp = JSON.parse(resp_body)
        if resp["response"] == "failure"
          error_hash << [variant.sku, variant.product.name, variant.upc,variant.width, variant.height, variant.depth, variant.weight, variant.cost_price , '' ,'' , resp["message"]]
          #if resp["message"].include? 'Sku has already been taken'
          #  variant.update_attributes(:updated_on_fba => true)
          #else
            variant.update_attributes(:updated_on_fba => false)
          #end
        else
          variant.update_attributes(:updated_on_fba => true)
          variant.recent_market_place_changes.where(:update_on_fba=>true).destroy_all #if variant.recent_market_place_changes.present?
        end

      end
    end
    if error_hash.present? && error_hash.size >= 2
      message = "You have some errors in updating products on FBA, for details PFA. Rest of the products are updated successfully"
      file = ImportJob.generate_excel(error_hash)
      Spree::ProductNotificationMailer::fail_on_fba(current_user.try(:email), message, file, "Product_error_on_FBA_#{Date.today.strftime('%d-%m-%Y')}.xls").deliver
    else
      message = "All the products are processed successfully on FBA"
      subject = "[Channel Manager] Status for Create/Update Products on FBA"

      Spree::ProductNotificationMailer::fail_on_fba(current_user.try(:email), subject, message, '', '' ).deliver
    end
  end
end
