Rails.configuration.to_prepare do
  require_dependency 'redmine_approve_list/acts_as_approvable'
  require_dependency 'redmine_approve_list/patches/user_patch'
  require_dependency 'redmine_approve_list/patches/issue_patch'
  require_dependency 'redmine_approve_list/patches/issues_controller_patch'
  require_dependency 'redmine_approve_list/patches/my_helper_patch'
  require_dependency 'redmine_approve_list/plugin_setting_helper'
end

module RedmineApproveList
  def self.settings() Setting[:plugin_redmine_approve_list] end
end
