object false
node(:count) { @users.count }
node(:total_count) { @users.count }
node(:current_page) { params[:page] ? params[:page].to_i : 1 }
node(:per_page) { params[:per_page] || Kaminari.config.default_per_page }
child @users => :users do
  extends "spree/api/users/show"
end