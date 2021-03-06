# encoding: utf-8
# Approvers Controller
class ApproversController < ApplicationController
  before_filter :require_login, :find_approvables, only: [:approve, :unapprove]
  before_filter :find_project, :authorize, only: [:do_approve, :undo_approve, :new, :create, :append, :destroy, :autocomplete_for_user]

  def approve
    set_approver(@approvables, User.current, true)
  end

  def unapprove
    set_approver(@approvables, User.current, false)
  end

  def do_approve
    set_approver_done(params[:reject].blank? ? true : false)
  end

  def undo_approve
    set_approver_done(false)
  end

  accept_api_auth :create, :destroy

  def new
    @users = users_for_new_approver
  end

  def create
    user_ids = []
    if params[:approver].is_a?(Hash)
      user_ids << (params[:approver][:user_ids] || params[:approver][:user_id])
    else
      user_ids << params[:user_id]
    end
    user_ids = Array(user_ids).flatten.map(&:to_i)
    user_ids = User.active.visible.allowed_to(:do_approve_issue)
                  .select(:id).where(id: user_ids.flatten.compact.uniq)
                  .index_by{|u| u.id }.values_at(*user_ids).compact.map(&:id)

    if user_ids != (old_user_ids = @approved.approver_user_ids) then
      @approved.approver_user_ids=user_ids
      if user_ids == @approved.approver_user_ids then
        journal=Journal.new(notes: "", user: User.current)
        journal.details << JournalDetail.new(property: "attr", prop_key: "approver_users", old_value: old_user_ids.to_json, value: user_ids.to_json)
        @approved.journals << journal
      end
    end

    respond_to do |format|
      format.html { redirect_to_referer_or {render text: 'Approver added.', layout: true}}
      format.js { @users = users_for_new_approver }
      format.api { render_api_ok }
    end
  end

  def append
    if params[:approver].is_a?(Hash)
      user_ids = params[:approver][:user_ids] || [params[:approver][:user_id]]
      @users = User.active.visible
        .allowed_to(:do_approve_issue)
        .where(id: user_ids).to_a
    end
    if @users.blank?
      render nothing: true
    end
  end

  def destroy
    #@approved.set_approver(User.visible.find(params[:user_id]), false)
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
      format.api { render_api_ok }
    end
  end

  def autocomplete_for_user
    @users = users_for_new_approver(false)
    render layout: false
  end

  private

  def find_project
    if params[:object_type] && params[:object_id]
      klass = Object.const_get(params[:object_type].camelcase)
      return false unless klass.respond_to?('approved_by')
      @approved = klass.find(params[:object_id])
      @project = @approved.project
    elsif params[:project_id]
      @project = Project.visible.find_by_param(params[:project_id])
    end
  rescue
    render_404
  end

  def find_approvables
    klass = Object.const_get(params[:object_type].camelcase) rescue nil
    if klass && klass.respond_to?('approved_by')
      @approvables = klass.where(id: Array.wrap(params[:object_id])).to_a
      raise Unauthorized if @approvables.any? {|w|
        if w.respond_to?(:visible?)
          !w.visible?
        elsif w.respond_to?(:project) && w.project
          !w.project.visible?
        end
      }
    end
    render_404 unless @approvables.present?
  end

  def set_approver(approvables, user, approving)
    approvables.each do |approvable|
      approvable.set_approver(user, approving)
    end
    respond_to do |format|
      format.html { redirect_to_referer_or {render text: (approving ? 'Approver added.' : 'Approver removed.'), layout: true}}
      format.js { render partial: 'set_approver', locals: {user: user, approved: approvables} }
    end
  end

  def set_approver_done(is_done)
    approver = Approver.find(params[:id])
    unless @approved.status_approver_active?
      flash[:error] = l(:error_approver_is_not_active)
      redirect_to @approved
      return
    end
    raise Unauthorized unless approver.can_done_by?(User.current)

    approver.update_attribute(:is_done, is_done)
    approver.next_approver.send_notification if is_done and not approver.is_last?

    # REJECT and all DONE actions
    status_was = @approved.status_was
    @approved.approver_reject! unless is_done
    @approved.approver_done! if is_done and approver.is_last?
    status = @approved.status

    # JOURNALING
    notes=""
    notes << "Done by admin for user #{approver.user}\n" if User.current.admin? and User.current != approver.user
    notes=params[:issue_notes]+"\n" unless params[:issue_notes].blank?
    journal=Journal.new(notes: notes, user: User.current)
    journal.details << JournalDetail.new(property: "attr", prop_key: "approver", old_value: (not is_done).to_s, value: is_done.to_s)
    journal.details << JournalDetail.new(property: "attr", prop_key: "status", old_value: status_was, value: status) if status != status_was
    @approved.journals << journal


    respond_to do |format|
      format.html { redirect_to_referer_or { render text: (approving ? 'Approve done.' : 'Approve undone.'), layout: true } }
      format.js { render partial: 'do_approve', locals: { user: approver.user } }
    end
  end

  def users_for_new_approver(remove_approved=true)
    scope = nil
    if params[:q].blank? && @project.present?
      scope = @project.users.allowed_to(:do_approve_issue)
    else
      scope = User.allowed_to(:do_approve_issue).limit(100)
    end
    users = scope.active.visible.sorted.like(params[:q]).to_a
    if @approved and remove_approved
      users -= @approved.approver_users
    end
    users
  end
end
