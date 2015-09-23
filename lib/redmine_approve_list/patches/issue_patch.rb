module RedmineApproveList
  module Patches

    module IssuePatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          acts_as_approvable

          safe_attributes 'approver_user_ids',
            :if => lambda {|issue, user| issue.new_record? && user.allowed_to?(:add_issue_approvers, issue.project)}
        end
      end

      module InstanceMethods
        def is_approver_active?
          return false if (statuses = Setting[:plugin_redmine_approve_list]["tracker_#{self.tracker_id}"] ).nil?
          return statuses[:active].to_i == self.status_id
        end

        %w(active reject done).each do |method|
          define_method "status_approver_#{method}" do
            return false if (statuses = Setting[:plugin_redmine_approve_list]["tracker_#{self.tracker_id}"] ).nil?
            return statuses[method].blank? ? false : statuses[method].to_i
          end
        end

        def approver_reject!
          self.approvers.update_all(is_done: false)
          self.update_attributes(status_id: status_approver_reject) if status_approver_reject
        end

        def approver_done!
          self.update_attributes(status_id: status_approver_done) if status_approver_done
        end

      end

    end
  end
end

unless Issue.included_modules.include?(RedmineApproveList::Patches::IssuePatch)
  Issue.send(:include, RedmineApproveList::Patches::IssuePatch)
end

