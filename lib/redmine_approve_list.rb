Rails.configuration.to_prepare do
  require_dependency 'redmine_approve_list/acts_as_approvable'
  require_dependency 'redmine_approve_list/patches/user_patch'
  require_dependency 'redmine_approve_list/patches/issue_patch'
  require_dependency 'redmine_approve_list/patches/issues_controller_patch'
  require_dependency 'redmine_approve_list/patches/issues_helper_patch'
  require_dependency 'redmine_approve_list/patches/my_helper_patch'
  require_dependency 'redmine_approve_list/patches/context_menus_controller_patch'
  require_dependency 'redmine_approve_list/plugin_setting_helper'
end



module RedmineApproveList
  def self.settings() Setting[:plugin_redmine_approve_list] end

  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      render_on :view_issues_context_menu_end, partial: "context_menu_approver"
      render_on :view_issues_form_details_bottom, partial: "issue_new_approvers"
      render_on :view_issues_sidebar_queries_bottom, partial: "issue_sidebar_approvers"
    end
  end
end
