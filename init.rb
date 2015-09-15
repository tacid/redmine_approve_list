require 'redmine_approve_list'

Redmine::Plugin.register :redmine_approve_list do
  name 'Redmine approve list'
  author 'Tacid'
  description 'This is a plugin that adds approve list to issues'
  version '0.1.0'
  url 'https://github.com/tacid/redmine_approve_list'
  author_url 'https://github.com/tacid'

  requires_redmine :version_or_higher => '3.0.0'

  settings default: {
    approve_tracker_ids: Tracker.all.map{|t| t.id.to_s},
  }, partial: 'settings/redmine_approve_list_settings'
end
