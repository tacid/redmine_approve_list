class CreateApprovers < ActiveRecord::Migration
  def self.up
    create_table Approver.table_name do |t|
      t.column :approvable_type, :string, :default => "", :null => false
      t.column :approvable_id, :integer, :default => 0, :null => false
      t.column :user_id, :integer
    end
    add_index Approver.table_name, :user_id
    add_index Approver.table_name, [:approvable_id, :approvable_type]
    add_index Approver.table_name, [:user_id, :approvable_type], :name => :approvers_user_id_type
  end

  def self.down
    drop_table Approver.table_name
  end
end
