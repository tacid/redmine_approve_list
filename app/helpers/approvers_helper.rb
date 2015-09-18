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
      s << content_tag('i', ' ', class: 'icon ' + (approver.is_done ? 'icon-fav' : 'icon-fav-off' ))
      s << avatar(user, :size => "16").to_s
      s << link_to_user(user, :class => 'user')
      if remove_allowed
        url = {:controller => 'approvers',
               :action => 'destroy',
               :object_type => object.class.to_s.underscore,
               :object_id => object.id,
               :user_id => user}
        s << ' '
        s << link_to(image_tag('delete.png'), url,
                     :remote => true, :method => 'delete', :class => "delete")
      end
      s << ' '
      if approver.user == User.current
        link = link_to( l("button_do_" + (approver.is_done ? "unapprove" : "approve")),
                {:controller => 'approvers',
                 :action => 'do_approve',
                 :object_type => object.class.to_s.underscore,
                 :object_id => object.id,
                 :id => approver.id },
               :remote => true, :method => (approver.is_done ? 'delete' : 'post'), :class => "do-approve")
        s << content_tag("div", link, class: "contextual")
      end
      if approver.is_done
        s << content_tag('p', "Согласовано: " + localize(approver.updated_at, format: :short))
      end
      content << content_tag('li', s, :class => "user-#{user.id}")
    end
    content.present? ? content_tag('ul', content, :class => 'approvers') : content
  end

  def approvers_checkboxes(object, users, checked=nil)
    users.map do |user|
      c = checked.nil? ? object.approved_by?(user) : checked
      tag = check_box_tag 'issue[approver_user_ids][]', user.id, c, :id => nil
      content_tag 'label', "#{tag} #{h(user)}".html_safe,
                  :id => "issue_approver_user_ids_#{user.id}",
                  :class => "floating"
    end.join.html_safe
  end
end
