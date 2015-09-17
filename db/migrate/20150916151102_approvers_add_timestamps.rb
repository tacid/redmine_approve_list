class ApproversAddTimestamps < ActiveRecord::Migration
  def change
    add_column Approver.table_name, :created_at, :datetime
    add_column Approver.table_name, :updated_at, :datetime
  end
end
