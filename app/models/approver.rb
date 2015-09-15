class Approver < ActiveRecord::Base
  belongs_to :approvable, :polymorphic => true
  belongs_to :user

  validates_presence_of :user
  validates_uniqueness_of :user_id, :scope => [:approvable_type, :approvable_id]
  validate :validate_user
  attr_protected :id

  # Returns true if at least one object among objects is approved by user
  def self.any_approved?(objects, user)
    objects = objects.reject(&:new_record?)
    if objects.any?
      objects.group_by {|object| object.class.base_class}.each do |base_class, objects|
        if approver.where(:approvable_type => base_class.name, :approvable_id => objects.map(&:id), :user_id => user.id).exists?
          return true
        end
      end
    end
    false
  end

  # Unwatch things that users are no longer allowed to view
  def self.prune(options={})
    if options.has_key?(:user)
      prune_single_user(options[:user], options)
    else
      pruned = 0
      User.where("id IN (SELECT DISTINCT user_id FROM #{table_name})").each do |user|
        pruned += prune_single_user(user, options)
      end
      pruned
    end
  end

  protected

  def validate_user
    errors.add :user_id, :invalid unless user.nil? || user.active?
  end

  private

  def self.prune_single_user(user, options={})
    return unless user.is_a?(User)
    pruned = 0
    where(:user_id => user.id).each do |approver|
      next if approver.approvable.nil?
      if options.has_key?(:project)
        unless approver.approvable.respond_to?(:project) &&
                 approver.approvable.project == options[:project]
          next
        end
      end
      if approver.approvable.respond_to?(:visible?)
        unless approver.approvable.visible?(user)
          approver.destroy
          pruned += 1
        end
      end
    end
    pruned
  end
end
