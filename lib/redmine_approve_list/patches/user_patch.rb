module RedmineApproveList
  module Patches

    module UserPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          alias_method_chain :remove_references_before_destroy, :approve

          # returns users for given permission
          def self.allowed_to(permission)
            includes(members: [:roles]).
              where(roles: {
                id: Role.where(Role.arel_table[:permissions].matches("%#{permission}%")).uniq
              }).uniq
          end
        end
      end

      module InstanceMethods
        private
        # Removes references that are not handled by associations
        def remove_references_before_destroy_with_approve
          remove_references_before_destroy_without_approve
          Approver.delete_all ['user_id = ?', id]
        end
      end

    end
  end
end

unless User.included_modules.include?(RedmineApproveList::Patches::UserPatch)
  User.send(:include, RedmineApproveList::Patches::UserPatch)
end

