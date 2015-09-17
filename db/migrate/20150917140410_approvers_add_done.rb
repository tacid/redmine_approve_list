class ApproversAddDone < ActiveRecord::Migration
  def change
    add_column Approver.table_name, :is_done, :boolean, null: false, default: false
  end
end
