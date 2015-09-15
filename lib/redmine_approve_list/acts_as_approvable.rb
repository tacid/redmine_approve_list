# ActsAsApprovable
module RedmineApproveList
  module Acts
    module Approvable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_approvable(options = {})
          return if self.included_modules.include?(RedmineApproveList::Acts::Approvable::InstanceMethods)
          class_eval do
            has_many :approvers, :as => :approvable, :dependent => :delete_all
            has_many :approver_users, :through => :approvers, :source => :user, :validate => false

            scope :approved_by, lambda { |user_id|
              joins(:approvers).
              where("#{Approver.table_name}.user_id = ?", user_id)
            }
            attr_protected :approver_ids, :approver_user_ids
          end
          send :include, RedmineApproveList::Acts::Approvable::InstanceMethods
          alias_method_chain :approver_user_ids=, :uniq_ids
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        # Returns an array of users that are proposed as approvers
        def addable_approver_users
          users = self.project.users.sort - self.approver_users
          if respond_to?(:visible?)
            users.reject! {|user| !visible?(user)}
          end
          users
        end

        # Adds user as a approver
        def add_approver(user)
          self.approvers << Approver.new(user: user)
        end

        # Removes user from the approvers list
        def remove_approver(user)
          return nil unless user && user.is_a?(User)
          approvers.where(:user_id => user.id).delete_all
        end

        # Adds/removes approver
        def set_approver(user, approving=true)
          approving ? add_approver(user) : remove_approver(user)
        end

        # Overrides approver_user_ids= to make user_ids uniq
        def approver_user_ids_with_uniq_ids=(user_ids)
          if user_ids.is_a?(Array)
            user_ids = user_ids.uniq
          end
          send :approver_user_ids_without_uniq_ids=, user_ids
        end

        # Returns true if object is approved by +user+
        def approved_by?(user)
          !!(user && self.approver_user_ids.detect {|uid| uid == user.id })
        end

        def notified_approvers
          notified = approver_users.active.to_a
          notified.reject! {|user| user.mail.blank? || user.mail_notification == 'none'}
          if respond_to?(:visible?)
            notified.reject! {|user| !visible?(user)}
          end
          notified
        end

        # Returns an array of approvers' email addresses
        def approver_recipients
          notified_approvers.collect(&:mail)
        end

        module ClassMethods; end
      end
    end
  end
end

unless ActiveRecord::Base.included_modules.include?(RedmineApproveList::Acts::Approvable)
  ActiveRecord::Base.send(:include, RedmineApproveList::Acts::Approvable)
end
