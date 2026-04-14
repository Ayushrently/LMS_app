class User < ApplicationRecord
    validates :email, presence: true, format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i}, uniqueness: { case_sensitive: false }
    validates :role, inclusion: { in: User.roles.keys }

    enum role:{ student:"student", author:"author", admin:"admin" }, _default: :student

    has_one :profile
    has_one :subscription, through: :profile
    has_many :comments
    has_many :enrollments
    has_many :courses, through: :enrollments
    has_and_belongs_to_many :authored_courses, class_name: 'Course', join_table: :courses_users
end
