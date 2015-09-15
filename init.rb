
require 'redmine_approve_list'

Redmine::Plugin.register :redmine_approve_list do
  name 'Redmine approve list'
  author 'Tacid'
  description 'This is a plugin that changes Redmine::Helper::Diff module to use htmldiff gem'
  version '0.0.1'
  url 'https://github.com/tacid/redmine_approve_list'
  author_url 'https://github.com/tacid'
  settings default: {
    approve_tracker_ids: Tracker.all.map{|t| t.id.to_s},
  }, partial: 'settings/redmine_approve_list_settings'
end
