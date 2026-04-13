class User < ApplicationRecord
    has_one :profile
    has_one :subscription, through: :profile
    has_many :comments
    has_many :enrollments
    has_many :courses, through: :enrollments
    has_and_belongs_to_many :authored_courses, class_name: 'Course', join_table: :courses_users
end
