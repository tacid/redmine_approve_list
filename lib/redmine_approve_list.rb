Rails.configuration.to_prepare do
  require_dependency 'redmine_approve_list/acts_as_approvable'
  require_dependency 'redmine_approve_list/patches/user_patch'
  require_dependency 'redmine_approve_list/patches/issue_patch'
  require_dependency 'redmine_approve_list/patches/issues_controller_patch'
  require_dependency 'redmine_approve_list/patches/issues_helper_patch'
  require_dependency 'redmine_approve_list/patches/my_helper_patch'
  require_dependency 'redmine_approve_list/patches/issue_query_patch'
  require_dependency 'redmine_approve_list/patches/mailer_patch'
  require_dependency 'redmine_approve_list/plugin_setting_helper'
end



module RedmineApproveList
  def self.settings() Setting[:plugin_redmine_approve_list] end

  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      render_on :view_issues_show_description_bottom, partial: "description_bottom_approver"
      render_on :view_issues_sidebar_queries_bottom, partial: "issue_sidebar_approvers"

      def helper_issues_show_detail_after_setting(context = { })
        detail = context[:detail]
        if detail.prop_key == "approver" then
          if detail.value.in?(%w(true false))
            detail.old_value = ""
            detail.value = detail.value == "true" ?  l("approver_done") : l("approver_undone")
          end
        elsif detail.prop_key == "approver_users"
          if /\[[0-9,]*\]/ =~ detail.old_value and /\[[0-9,]*\]/ =~ detail.value
            old_uids = Array(JSON.parse(detail.old_value))
            cur_uids = Array(JSON.parse(detail.value))
            detail.old_value = (old_uids.empty? ? "" : User.where(id: old_uids).join(', ') )
            detail.value =     (cur_uids.empty? ? "" : User.where(id: cur_uids).join(', ') )
          end
        end
      end


      def controller_issues_edit_before_save(context={})
        @status_id_was = context[:issue].status_id_was
      end

      def controller_issues_edit_after_save(context={})
        # Check if the status changed
        return if @status_id_was == context[:issue].status_id

        # Send notification to first approver if new status is approver active status
        context[:issue].approvers.find_by(is_done: false).send_notification if context[:issue].status_approver_active?
      end

    end
  end
end

