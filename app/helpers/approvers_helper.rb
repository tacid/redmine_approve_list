# encoding: utf-8

module ApproversHelper

  def approver_link(objects, user)
    return '' unless user && user.logged?
    objects = Array.wrap(objects)
    return '' unless objects.any?

    approved = Approver.any_approved?(objects, user)
    css = [approver_css(objects), approved ? 'icon icon-fav' : 'icon icon-fav-off'].join(' ')
    text = approved ? l(:button_unapprove) : l(:button_approve)
    url = approve_path(
      :object_type => objects.first.class.to_s.underscore,
      :object_id => (objects.size == 1 ? objects.first.id : objects.map(&:id).sort)
    )
    method = approved ? 'delete' : 'post'

    link_to text, url, :remote => true, :method => method, :class => css
  end

  def do_approve_link(objects, user)
    return '' unless user && user.logged?
    objects = Array.wrap(objects)
    return '' unless objects.any?

    approved = Approver.any_approved?(objects, user)
    css = [approver_css(objects), approved ? 'icon icon-fav' : 'icon icon-fav-off'].join(' ')
    text = approved ? l(:button_unapprove) : l(:button_approve)
    url = approve_path(
      :object_type => objects.first.class.to_s.underscore,
      :object_id => (objects.size == 1 ? objects.first.id : objects.map(&:id).sort)
    )
    method = approved ? 'delete' : 'post'

    link_to text, url, :remote => true, :method => method, :class => css
  end

  # Returns the css class used to identify approve links for a given +object+
  def approver_css(objects)
    objects = Array.wrap(objects)
    id = (objects.size == 1 ? objects.first.id : 'bulk')
    "#{objects.first.class.to_s.underscore}-#{id}-approver"
  end

  # Returns a comma separated list of users approving the given object
  def approvers_list(object)
    remove_allowed = User.current.allowed_to?("delete_#{object.class.name.underscore}_approvers".to_sym, object.project)
    content = ''.html_safe
    lis = object.approver_users.collect do |user|
      approver = object.approvers.where(user_id: user.id).first
      s = ''.html_safe
      s << avatar(user, :size => "16").to_s
      s << link_to_user(user, :class => 'user')
      if approver.is_done
        s << content_tag('p', l(:approver_done) +": " + format_time(approver.updated_at))
      end
      content << content_tag('li', s, :class => "user-#{user.id}")
    end
    content.present? ? content_tag('ol', content, :class => 'approvers') : content
  end

  def approvers_checkboxes(object, users, checked=nil, name="issue[approvers][]")
    users.map do |user|
      c = checked.nil? ? object.approved_by?(user) : checked
      tag = check_box_tag(name, user.id, c, :id => nil)
      content_tag 'label', "#{tag} #{h(user)}".html_safe,
                  :id => "#{name.parameterize("_")}_#{user.id}",
                  :class => "floating"
    end.join.html_safe
  end
end
