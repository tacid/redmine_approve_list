Rails.configuration.to_prepare do
  require_dependency 'redmine_approve_list/patches/user_patch'
  require_dependency 'redmine_approve_list/plugin_setting_helper'
end

module RedmineApproveList
  def self.settings() Setting[:plugin_approve_list] end
end
