class ApproversAddIndex < ActiveRecord::Migration
  def change
    add_column Approver.table_name, :index, :integer, null: 0, default: 0
  end
end
