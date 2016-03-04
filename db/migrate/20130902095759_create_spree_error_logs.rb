class CreateSpreeErrorLogs < ActiveRecord::Migration
  def change
    create_table :spree_error_logs do |t|
    	t.string 	:title
      t.text 		:log
      t.string 	:status
      t.string 	:git_reference

      t.timestamps
    end
  end
end
