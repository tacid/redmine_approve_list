class RenameApproversIndex < ActiveRecord::Migration
  def change
    rename_column Approver.table_name, :index, :order_index
  end
end
