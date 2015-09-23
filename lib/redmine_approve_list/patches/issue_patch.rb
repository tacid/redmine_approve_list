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

        def current_approver
          @current_approver ||= self.approvers.find_by(is_done: false)
        end

        def can_be_approved_by?(user=User.current)
          return false unless User.allowed_to(:do_approve_issue).include?(user)
          return self.current_approver.can_done_by?(user)
        end

        def is_approver_on?
          Setting[:plugin_redmine_approve_list][:tracker_ids].include?(self.tracker_id.to_s)
        end

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
          self.approvers.first.send_notification unless status_approver_reject
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

