class Enrollment < ApplicationRecord
  validates :user_id, uniqueness: { scope: :course_id }
  
  belongs_to :user
  belongs_to :course
end
