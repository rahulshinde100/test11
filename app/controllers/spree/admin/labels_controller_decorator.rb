Spree::Admin::LabelsController.class_eval do

  def index
    if params[:format] == "json"
      q = params[:q]
      search = params[:search]
      seller_id = params[:seller_id]
      
      if current_spree_user.has_spree_role?("admin")
        cond = ""
        if q.present?
          cond = "(title like '%#{q}%' || color like '%#{q}%'|| shape like '%#{q}%')"
        end

        if seller_id.present?
          cond += (cond.blank? ? "" : " and ") + "seller_id = #{seller_id}"
        end
        
        labels = Spree::Label.where(cond)
      else
        labels = current_spree_user.seller.labels.where("title like '%#{q}%' || color like '%#{q}%'|| shape like '%#{q}%'")
      end
      

      if search.present?
        labels = Spree::Label.where(:id => search.split(","))
      end
      @labels = []

      #labels.blank? ? [] : labels
      labels.each do |label|
        @labels.push(label.attributes)
      end unless labels.nil?
    else
      @labels = current_spree_user.has_spree_role?("admin") ? Spree::Label.order("is_approved") : current_spree_user.seller.labels
    end

    respond_with(@labels) do |format|
      format.html
      format.json
    end
  end

  def update
    unless current_spree_user.has_spree_role?("admin")
      params[:label].merge!(:is_approved => false)
    end
    super
  end

end		
