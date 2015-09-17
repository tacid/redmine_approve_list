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
            add_available_filter "approver_id",
              :type => :list, :values => [["<< #{l(:label_me)} >>", "me"]]
          end
        end

        def sql_for_approver_id_field(field, operator, value)
          db_table = Approver.table_name

          # "me" value substitution
          if value.delete("me")
            User.current.logged? ? value.push(User.current.id.to_s) : value.push("0")
          end
          "#{Issue.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{db_table}.approvable_id FROM #{db_table} WHERE #{db_table}.approvable_type='Issue' AND " +
            sql_for_field(field, '=', value, db_table, 'user_id') + ')'
        end
      end

    end
  end
end

unless IssueQuery.included_modules.include?(RedmineApproveList::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineApproveList::Patches::IssueQueryPatch)
end

