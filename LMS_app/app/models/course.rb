# frozen_string_literal: true

class Course < ApplicationRecord
  validates :title, :description, presence: true
  validates :title, length: { in: 5..100 }, uniqueness: { case_sensitive: false }
  validates :description, length: { in: 10..600 }

  enum :tier, { free: 'free', pro: 'pro' }, default: :free
  has_many :enrollments, dependent: :destroy
  has_many :users, through: :enrollments
  has_many :lessons, dependent: :destroy
  has_and_belongs_to_many :authors,
                          class_name: 'User',
                          join_table: :courses_users,
                          before_add: :prevent_duplicate_author,
                          after_add: :ensure_author_enrollment,
                          before_remove: :prevent_creator_author_removal,
                          after_remove: :remove_author_enrollment
  has_many :comments, as: :commentable, dependent: :destroy

  default_scope { where(deleted_at: nil) }
  scope :soft_deleted, -> { where.not(deleted_at: nil) }

  def soft_deleted?
    deleted_at.present?
  end

  def soft_delete!
    return destroy unless enrollments.any?

    transaction do
      author_ids_to_clean = authors.pluck(:id)

      authors.delete_all
      enrollments.where(user_id: author_ids_to_clean).destroy_all

      update!(deleted_at: Time.current)
    end
  end

  def creator_identifier_matches?(author)
    return false if creator.blank? || author.blank?

    identifiers = [author.profile&.username, author.profile&.name, author.email].compact
    identifiers.include?(creator)
  end

  private

  def remove_author_enrollment(author)
    enrollments.destroy_by(user: author)
  end

  def ensure_author_enrollment(author)
    enrollments.find_or_create_by(user: author)
  end

  def prevent_duplicate_author(author)
    return unless authors.exists?(author.id)

    errors.add(:authors, 'already includes this user')
    throw(:abort)
  end

  def prevent_creator_author_removal(author)
    return unless creator_identifier_matches?(author)

    errors.add(:authors, 'cannot remove course creator')
    throw(:abort)
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[enrollments authors users]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id title description tier creator created_at updated_at deleted_at]
  end
end
