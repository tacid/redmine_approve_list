require 'redmine_approve_list'

Redmine::Plugin.register :redmine_approve_list do
  name 'Redmine approve list'
  author 'Tacid'
  description 'This is a plugin that adds approve list to issues'
  version '0.1.0'
  url 'https://github.com/tacid/redmine_approve_list'
  author_url 'https://github.com/tacid'

  requires_redmine :version_or_higher => '3.0.0'

  Redmine::AccessControl.map do |map|
    map.project_module :issue_tracking do |map|
      map.permission :view_issue_approvers, {}, :read => true
      map.permission :add_issue_approvers, {:approvers => [:new, :create, :append, :autocomplete_for_user]}
      map.permission :delete_issue_approvers, {:approvers => :destroy}
      map.permission :import_issues, {:imports => [:new, :create, :settings, :mapping, :run, :show]}
    end
  end

  settings default: {
    approve_tracker_ids: Tracker.all.map{|t| t.id.to_s},
  }, partial: 'settings/redmine_approve_list_settings'
end
