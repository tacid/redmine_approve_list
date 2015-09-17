module RedmineApproveList
  module Patches

    module ContextMenusControllerPatch
      def self.included(base) # :nodoc:
        base.class_eval do
          helper :approvers
        end
      end
    end
  end
end

unless ContextMenusController.included_modules.include?(RedmineApproveList::Patches::ContextMenusControllerPatch)
  ContextMenusController.send(:include, RedmineApproveList::Patches::ContextMenusControllerPatch)
end

