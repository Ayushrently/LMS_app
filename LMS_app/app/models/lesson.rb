class Lesson < ApplicationRecord
  before_validation :preprocess_data

  validates :title, presence: true, length: { in: 5..20 }, uniqueness: { scope: :course_id }
  validates :content, presence: true, length: { minimum: 20 }

  belongs_to :course
  has_many :comments, as: :commentable

  def self.ransackable_attributes(auth_object = nil)
    ["title", "content", "created_at", "id", "course_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["course"]
  end

  private
  def preprocess_data
    self.title = title.strip unless title.nil?
    self.content = content.strip unless content.nil?
  end
end
