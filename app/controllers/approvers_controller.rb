# encoding: utf-8

class ApproversController < ApplicationController
  before_filter :require_login, :find_approvables, :only => [:approve, :unapprove]

  def approve
    set_approver(@approvables, User.current, true)
  end

  def unapprove
    set_approver(@approvables, User.current, false)
  end

  def do_approve
    set_approver_done(true)
  end
  def undo_approve
    set_approver_done(false)
  end


  before_filter :find_project, :authorize, :only => [:new, :create, :append, :destroy, :autocomplete_for_user]
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
    users = User.active.visible.where(:id => user_ids.flatten.compact.uniq)
    users.each do |user|
      Approver.create(:approvable => @approved, :user => user)
    end
    respond_to do |format|
      format.html { redirect_to_referer_or {render :text => 'Approver added.', :layout => true}}
      format.js { @users = users_for_new_approver }
      format.api { render_api_ok }
    end
  end

  def append
    if params[:approver].is_a?(Hash)
      user_ids = params[:approver][:user_ids] || [params[:approver][:user_id]]
      @users = User.active.visible.where(:id => user_ids).to_a
    end
    if @users.blank?
      render :nothing => true
    end
  end

  def destroy
    @approved.set_approver(User.visible.find(params[:user_id]), false)
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
      format.api { render_api_ok }
    end
  end

  def autocomplete_for_user
    @users = users_for_new_approver
    render :layout => false
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
      @approvables = klass.where(:id => Array.wrap(params[:object_id])).to_a
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
      format.html { redirect_to_referer_or {render :text => (approving ? 'Approver added.' : 'Approver removed.'), :layout => true}}
      format.js { render :partial => 'set_approver', :locals => {:user => user, :approved => approvables} }
    end
  end

  def set_approver_done(is_done)
    this = Approver.find(params[:id])
    return unless User.current == this.user
    this.update_attribute(:is_done, is_done)
    @approved = this.approvable
    respond_to do |format|
      format.html { redirect_to_referer_or {render :text => (approving ? 'Approve done.' : 'Approve undone.'), :layout => true}}
      format.js { render :partial => 'do_approve', :locals => {:user => this.user } }
    end
  end

  def users_for_new_approver
    scope = nil
    if params[:q].blank? && @project.present?
      scope = @project.users
    else
      scope = User.all.limit(100)
    end
    users = scope.active.visible.sorted.like(params[:q]).to_a
    if @approved
      users -= @approved.approver_users
    end
    users
  end
end
