class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
    enum role:{ student:"student", author:"author" }, _default: :student, _prefix: true
    validates :role, inclusion: { in: User.roles.keys }


    has_one :profile, dependent: :destroy
    has_one :subscription, through: :profile, dependent: :destroy
    has_many :comments
    has_many :enrollments, dependent: :destroy
    has_many :courses, through: :enrollments
    has_and_belongs_to_many :authored_courses, class_name: 'Course', join_table: :courses_users
end
