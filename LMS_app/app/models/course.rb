class Course < ApplicationRecord
    validates :title, :description, presence: true
    validates :title, length: { in: 5..100 }, uniqueness: { case_sensitive:false }
    validates :description, length: { in: 50..600 }

    enum tier: { free:"free", pro:"pro" }, _default: :free
    has_many :enrollments
    has_many :users, through: :enrollments
    has_many :lessons
    has_and_belongs_to_many :authors, class_name: 'User', join_table: :courses_users
    has_many :comments, as: :commentable
end
