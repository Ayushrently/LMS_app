class Enrollment < ApplicationRecord
  validates :user_id, uniqueness: { scope: :course_id }
  
  belongs_to :user
  belongs_to :course

  def self.ransackable_attributes(auth_object = nil)
    ["course_id", "user_id", "created_at", "updated_at", "id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["course", "user"]
  end

end
