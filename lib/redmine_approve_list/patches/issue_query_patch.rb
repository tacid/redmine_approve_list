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
          issues = Issue.arel_table
          approvers = Approver.arel_table
          appr_alias = Arel::Table.new(Approver.table_name)
          appr_alias.table_alias = "approvers_min"

          # "me" value substitution
          if value.delete("me")
            User.current.logged? ? value.push(User.current.id.to_s) : value.push("0")
          end

          active_query = ''
          active_query = Setting[:plugin_redmine_approve_list]["tracker_ids"].map { |tid|
            if ( @tracker_ids ||= Tracker.all.pluck(:id) ).include?(tid.to_i)
              if (statuses = Setting[:plugin_redmine_approve_list]["tracker_#{tid}"]) and (active_sid = statuses[:active].to_i) > 0
                '(' + issues[:tracker_id].eq(tid.to_i).and(issues[:status_id].eq(active_sid)).to_sql + ')'
              end
            end
          }.compact.join(" OR ")
          active_query = '(' + active_query + ') AND ' unless active_query.blank?
          active_query << issues[:id].send((operator == '=' ? 'in' : 'not_in'),
            approvers.where(
                approvers[:approvable_type].eq('Issue')
              .and(
                approvers[:user_id].in(value))
              .and(
                approvers[:is_done].eq(false))
              .and(
                approvers[:order_index].eq(
                  appr_alias.where(
                      approvers[:approvable_type].eq(appr_alias[:approvable_type])
                    .and(
                      approvers[:approvable_id].eq(appr_alias[:approvable_id]))
                    .and(
                      approvers[:is_done].eq(appr_alias[:is_done])))
                  .project(appr_alias[:order_index].minimum)
               )))
            .project(approvers[:approvable_id])).to_sql
          active_query
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

