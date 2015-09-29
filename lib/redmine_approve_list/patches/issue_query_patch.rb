module RedmineApproveList
  module Patches

    module IssueQueryPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :initialize_available_filters, :approve
        end
      end

      module InstanceMethods
        def initialize_available_filters_with_approve
          initialize_available_filters_without_approve
          if User.current.logged?
            add_available_filter "approver.approver_id", label: "filter_approver_in_list",
              :type => :list, :values => [["<< #{l(:label_me)} >>", "me"]]
            add_available_filter "approver.need_approval_by", label: "filter_need_approval_by",
              :type => :list, :values => [["<< #{l(:label_me)} >>", "me"]]
            add_available_filter "approver.approved_by", label: "filter_approved_by",
              :type => :list, :values => [["<< #{l(:label_me)} >>", "me"]]
          end
        end

        define_method "sql_for_approver.approver_id_field" do |field, operator, value|
          db_table = Approver.table_name

          # "me" value substitution
          if value.delete("me")
            User.current.logged? ? value.push(User.current.id.to_s) : value.push("0")
          end
          "#{Issue.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{db_table}.approvable_id FROM #{db_table} WHERE #{db_table}.approvable_type='Issue' AND " +
            sql_for_field(field, '=', value, db_table, 'user_id') + ')'
        end

        define_method "sql_for_approver.need_approval_by_field" do |field, operator, value|
          db_table = Approver.table_name

          # "me" value substitution
          if value.delete("me")
            User.current.logged? ? value.push(User.current.id.to_s) : value.push("0")
          end
          "#{Issue.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{db_table}.approvable_id FROM #{db_table} WHERE #{db_table}.approvable_type='Issue' AND " +
            sql_for_field(field, '=', value, db_table, 'user_id') + ' AND ' +
            Approver.arel_table[:is_done].eq(false).to_sql + ' AND ' +
            "#{db_table}.'index' = ( SELECT MIN(a3.'index') FROM #{db_table} a3 WHERE a3.is_done=#{db_table}.is_done AND a3.approvable_type=#{db_table}.approvable_type AND a3.approvable_id=#{db_table}.approvable_id)" +
            ')'
        end

        define_method "sql_for_approver.approved_by_field" do |field, operator, value|
          db_table = Approver.table_name

          # "me" value substitution
          if value.delete("me")
            User.current.logged? ? value.push(User.current.id.to_s) : value.push("0")
          end
          "#{Issue.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{db_table}.approvable_id FROM #{db_table} WHERE #{db_table}.approvable_type='Issue' AND " +
            sql_for_field(field, '=', value, db_table, 'user_id') + ' AND ' +
            Approver.arel_table[:is_done].eq(true).to_sql + ')'
        end
      end

    end
  end
end

unless IssueQuery.included_modules.include?(RedmineApproveList::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineApproveList::Patches::IssueQueryPatch)
end

