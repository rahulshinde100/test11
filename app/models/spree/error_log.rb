class Spree::ErrorLog < ActiveRecord::Base
  attr_accessible :title, :log, :status, :git_reference
  
end
