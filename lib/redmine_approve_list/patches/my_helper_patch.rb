module RedmineApproveList
  module Patches

    module MyHelperPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          def issuesapproved_items
            Issue.visible.on_active_project
              .on_active_approval
              .need_approval_by(User.current.id)
              .recently_updated.limit(10).to_a
          end
        end
      end
    end
  end
end

unless MyHelper.included_modules.include?(RedmineApproveList::Patches::MyHelperPatch)
  MyHelper.send(:include, RedmineApproveList::Patches::MyHelperPatch)
end

