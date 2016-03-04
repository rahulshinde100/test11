Spree::Admin::TaxonsController.class_eval do
  after_filter :clear_taxonomy_cache, :only => [:create, :update]

  protected
  def clear_taxonomy_cache
    expire_fragment("taxonomies")
  end
end
