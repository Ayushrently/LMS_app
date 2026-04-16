class Lesson < ApplicationRecord
  before_validation :preprocess_data

  validates :title, presence: true, length: { in: 5..20 }, uniqueness: { scope: :course_id }
  validates :content, presence: true, length: { minimum: 20 }
  validates :position, presence:true, numericality: { greater_than: 0, only_integer: true }, uniqueness: { scope: :course_id }

  belongs_to :course
  has_many :comments, as: :commentable

  private
  def preprocess_data
    self.title = title.strip unless title.nil?
    self.content = content.strip unless content.nil?
  end
end
