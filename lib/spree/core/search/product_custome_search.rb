module Spree
  module Core
    module Search
      class ProductCustomeSearch
        attr_accessor :properties
        attr_accessor :current_user
        attr_accessor :current_currency

        def initialize(params)
          self.current_currency = Spree::Config[:currency]
          @properties = {}
          prepare(params)
        end

        def retrieve_products
          @products_scope = get_base_scope
          curr_page = page || 1

          # @products = @products_scope.includes([:master => :prices])
          # unless Spree::Config.show_products_without_price
          #   @products = @products.where("spree_prices.amount IS NOT NULL").where("spree_prices.currency" => current_currency)
          # end                    
          # @products = @products.page(curr_page).per(per_page)
          @products = Kaminari.paginate_array(@products_scope).page(curr_page).per(per_page)
        end

        def method_missing(name)
          if @properties.has_key? name
            @properties[name]
          else
            super
          end
        end

        protected
          def get_base_scope            
            base_scope = (seller.blank? ? Spree::Product : seller.products).active
            base_scope = base_scope.in_taxon(taxon) unless taxon.blank?                        
            base_scope = add_search_scopes(base_scope)
            base_scope = search_priority(base_scope, keywords) unless keywords.blank?
            base_scope
          end

          def add_search_scopes(base_scope)
            search.each do |name, scope_attribute|
              scope_name = name.to_sym
              if base_scope.respond_to?(:search_scopes) && base_scope.search_scopes.include?(scope_name.to_sym)
                base_scope = base_scope.send(scope_name, *scope_attribute)
              else
                base_scope = base_scope.merge(Spree::Product.ransack({scope_name => scope_attribute}).result)
              end
            end if search
            base_scope
          end

          # method should return new scope based on base_scope
          def get_products_conditions_for(base_scope, query)          
            unless query.blank?              
              base_scope.includes([:taxons, :seller, :product_properties]).where("spree_products.name like ? or spree_taxons.name like ? or spree_sellers.name like ? or spree_sellers.description like ? or spree_product_properties.value like ? or spree_products.description like ? or spree_products.meta_description like ? or spree_products.meta_keywords like ? or spree_products.company like ?", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
            end
            base_scope
          end

          def prepare(params)
            @properties[:taxon] = params[:taxon].blank? ? nil : Spree::Taxon.find(params[:taxon])
            @properties[:seller] = params[:retailer].blank? ? nil : Spree::Seller.find_by_permalink(params[:retailer])
            @properties[:keywords] = params[:keywords]
            @properties[:search] = params[:search]            

            per_page = params[:per_page].to_i
            @properties[:per_page] = per_page > 0 ? per_page : 30
            @properties[:page] = (params[:page].to_i <= 0) ? 1 : params[:page].to_i
            @properties[:show_all] = params[:show_all]
          end

          def search_priority(base_scope, query)
            search_priority = base_scope
            search_result = []
            unless query.blank?   
              base_scoped = base_scope.where("name = ? ", "#{query}")
              search_result << base_scoped
              base_scoped = base_scope.where("name like ? ", "#{query} %")
              search_result << base_scoped
              base_scoped = base_scope.where("name like ? ", "% #{query} %")
              search_result << base_scoped
              base_scoped = base_scope.where("name like ? ", "% #{query}")
              search_result << base_scoped
              if Spree::Seller.is_active.where("name like ? ","%#{query}%").present?
                base_scoped = search_priority.includes(:seller).where("spree_sellers.name = ? ", "#{query}")
                search_result << base_scoped
                base_scoped = search_priority.includes(:seller).where("spree_sellers.name like ? ", "#{query} %")
                search_result << base_scoped
                base_scoped = search_priority.includes(:seller).where("spree_sellers.name like ? ", "% #{query} %")
                search_result << base_scoped
                base_scoped = search_priority.includes(:seller).where("spree_sellers.name like ? ", "% #{query}")
                search_result << base_scoped
              end              
              taxon = Spree::Taxon.where("name like ? ","%#{query}%")
              if taxon.present?
                base_scoped = search_priority.includes(:taxons).where("spree_taxons.name = ? ", "#{query}")
                search_result << base_scoped
                base_scoped = search_priority.includes(:taxons).where("spree_taxons.name like ? ", "#{query} %")
                search_result << base_scoped
                base_scoped = search_priority.includes(:taxons).where("spree_taxons.name like ? ", "% #{query} %")
                search_result << base_scoped
                base_scoped = search_priority.includes(:taxons).where("spree_taxons.name like ? ", "% #{query}")
                search_result << base_scoped
              end              
              if Spree::ProductProperty.where("value like ?", "%#{query}%").present?
                base_scoped = search_priority.includes(:product_properties).where("spree_product_properties.value = ? ", "#{query}")
                search_result << base_scoped
                base_scoped = search_priority.includes(:product_properties).where("spree_product_properties.value like ? ", "#{query} %")
                search_result << base_scoped
                base_scoped = search_priority.includes(:product_properties).where("spree_product_properties.value like ? ", "% #{query} %")
                search_result << base_scoped
                base_scoped = search_priority.includes(:product_properties).where("spree_product_properties.value like ? ", "% #{query}")
                search_result << base_scoped
              end              
              if base_scoped.blank?
                base_scoped = search_priority.includes(:seller).where("spree_products.description like ? or spree_products.description like ? or spree_products.meta_description like ? or spree_products.meta_keywords like ? or spree_products.company like ? or spree_sellers.description like ? or spree_sellers.description like ? ", "%#{query}<%", "%#{query} %", "%#{query} %", "%#{query} %", "%#{query} %", "%#{query} %", "%#{query}<%")            
                search_result << base_scoped
              end              
              if base_scoped.blank?            
                query.split.each do |q|  
                  base_scoped = search_priority.where("name like ? or description like ? or meta_description like ?  or meta_keywords like ? or company like ?", "% #{q} %", "% #{q} %", "% #{q} %", "% #{q} %", "% #{q} %")
                  search_result << base_scoped
                  base_scoped = search_priority.where("name like ? or description like ? or meta_description like ?  or meta_keywords like ? or company like ?", "#{q} %", "#{q} %", "#{q} %", "#{q} %", "#{q} %")
                  search_result << base_scoped
                  base_scoped = search_priority.where("name like ? or description like ? or meta_description like ?  or meta_keywords like ? or company like ?", "% #{q}", "% #{q}", "% #{q}", "% #{q}", "% #{q}")
                  search_result << base_scoped
                end if query.present?
              end              
              search_result.flatten.uniq
            end
          end
      end
    end
  end
end