class FixTimesptampsColumnNames < ActiveRecord::Migration
  def change
    rename_column Approver.table_name, :updated_at, :updated_on
    rename_column Approver.table_name, :created_at, :created_on
  end
end
