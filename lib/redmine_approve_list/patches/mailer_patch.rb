module RedmineApproveList
  module Patches

    module MailerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          # Builds a mail for notifying to_users about approving
          def approver_notification(approver, to_users)
            issue = approver.approvable.reload
            redmine_headers 'Project' => issue.project.identifier,
                            'Issue-Id' => issue.id,
                            'Issue-Author' => issue.author.login
            redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
            message_id approver
            references issue
            @author = User.current || issue.user
            s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
            s << "(#{l(:need_approval)}) "
            s << issue.subject
            @issue = issue
            @users = to_users
            @approver = approver
            @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{approver.id}")
            mail :to => to_users,
              :subject => s
          end

          # Notifies users about an approving
          def self.deliver_approver_notification(approver)
            issue = approver.approvable.reload
            to = Array(approver.user)
            Mailer.approver_notification(approver, to).deliver
          end

        end
      end

      module InstanceMethods
      end

    end
  end
end

unless Mailer.included_modules.include?(RedmineApproveList::Patches::MailerPatch)
  Mailer.send(:include, RedmineApproveList::Patches::MailerPatch)
end

