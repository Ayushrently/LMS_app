class Course < ApplicationRecord
    validates :title, :description, presence: true
    validates :title, length: { in: 5..100 }, uniqueness: { case_sensitive:false }
    validates :description, length: { in: 10..600 }

    enum tier: { free:"free", pro:"pro" }, _default: :free
    enum status: { published:"published", draft:"draft" }, _default: :draft
    has_many :enrollments, dependent: :destroy
    has_many :users, through: :enrollments
    has_many :lessons, dependent: :destroy
    has_and_belongs_to_many :authors, class_name: 'User', join_table: :courses_users
    has_many :comments, as: :commentable, dependent: :destroy
end
