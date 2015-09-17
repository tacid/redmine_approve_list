module RedmineApproveList
  module Patches

    module IssuesHelperPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          # Returns an array of users that are proposed as approvers
          # on the new issue form
          def users_for_new_issue_approvers(issue)
            users = issue.approver_users
            if issue.project.users.count <= 20
              users = (users + issue.project.users.sort).uniq
            end
            users
          end
        end
      end

      module InstanceMethods
      end

    end
  end
end

unless IssuesHelper.included_modules.include?(RedmineApproveList::Patches::IssuesHelperPatch)
  IssuesHelper.send(:include, RedmineApproveList::Patches::IssuesHelperPatch)
end

