class User < ApplicationRecord
    enum role:{ student:"student", author:"author" }, _default: :student, _prefix: true
    validates :email, presence: true, format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i}, uniqueness: { case_sensitive: false }
    validates :role, inclusion: { in: User.roles.keys }


    has_one :profile, dependent: :destroy
    has_one :subscription, through: :profile, dependent: :destroy
    has_many :comments
    has_many :enrollments, dependent: :destroy
    has_many :courses, through: :enrollments
    has_and_belongs_to_many :authored_courses, class_name: 'Course', join_table: :courses_users
end
