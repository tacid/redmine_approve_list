module RedmineApproveList
  module Patches

    module IssuesControllerPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          helper :approvers
        end
      end
    end
  end
end

unless IssuesController.included_modules.include?(RedmineApproveList::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineApproveList::Patches::IssuesControllerPatch)
end

