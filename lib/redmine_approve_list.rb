Rails.configuration.to_prepare do
  require_dependency 'redmine_approve_list/acts_as_approvable'
  require_dependency 'redmine_approve_list/patches/user_patch'
  require_dependency 'redmine_approve_list/patches/issue_patch'
  require_dependency 'redmine_approve_list/patches/issues_controller_patch'
  require_dependency 'redmine_approve_list/patches/issues_helper_patch'
  require_dependency 'redmine_approve_list/patches/my_helper_patch'
  require_dependency 'redmine_approve_list/patches/context_menus_controller_patch'
  require_dependency 'redmine_approve_list/patches/issue_query_patch'
  require_dependency 'redmine_approve_list/plugin_setting_helper'
end



module RedmineApproveList
  def self.settings() Setting[:plugin_redmine_approve_list] end

  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      render_on :view_issues_context_menu_end, partial: "context_menu_approver"
      render_on :view_issues_show_description_bottom, partial: "description_bottom_approver"
      render_on :view_issues_sidebar_queries_bottom, partial: "issue_sidebar_approvers"

      def helper_issues_show_detail_after_setting(context = { })
        detail = context[:detail]
        if detail.prop_key == "approver" then
              detail.value = detail.value == "true" ?  l("approver_done") : l("approver_undone")
              detail.old_value = detail.old_value == "true" ? l("approver_done") : ""
        end
      end

    end
  end
end
