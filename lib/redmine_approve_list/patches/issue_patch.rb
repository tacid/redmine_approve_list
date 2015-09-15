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
      end

    end
  end
end

unless Issue.included_modules.include?(RedmineApproveList::Patches::IssuePatch)
  Issue.send(:include, RedmineApproveList::Patches::IssuePatch)
end

