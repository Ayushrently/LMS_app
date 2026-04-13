class Course < ApplicationRecord
    has_many :enrollments
    has_many :users, through: :enrollments
    has_many :lessons
    has_and_belongs_to_many :authored_courses, class_name: 'User', join_table: :courses_users
    has_many :comments, as: :commentable
end
