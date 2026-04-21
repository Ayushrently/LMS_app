class Course < ApplicationRecord
    validates :title, :description, presence: true
    validates :title, length: { in: 5..100 }, uniqueness: { case_sensitive:false }
    validates :description, length: { in: 10..600 }

    enum tier: { free:"free", pro:"pro" }, _default: :free
    has_many :enrollments, dependent: :destroy
    has_many :users, through: :enrollments
    has_many :lessons, dependent: :destroy
    has_and_belongs_to_many :authors,
                            class_name: 'User',
                            join_table: :courses_users,
                            after_add: :ensure_author_enrollment,
                            before_remove: :prevent_creator_author_removal,
                            after_remove: :remove_author_enrollment
    has_many :comments, as: :commentable, dependent: :destroy

    private

    def remove_author_enrollment(author)
        enrollments.destroy_by(user: author)
    end
    
    def ensure_author_enrollment(author)
        enrollments.find_or_create_by(user: author)
    end

    def prevent_creator_author_removal(author)
        return unless creator_identifier_matches?(author)

        errors.add(:authors, "cannot remove course creator")
        throw(:abort)
    end

    def creator_identifier_matches?(author)
        return false if creator.blank? || author.blank?

        identifiers = [author.profile&.username, author.profile&.name, author.email].compact
        identifiers.include?(creator)
    end
end
