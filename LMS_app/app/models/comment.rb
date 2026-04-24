class Comment < ApplicationRecord
  validates :body, presence:true, length: { in: 5..1000 }

  belongs_to :user
  belongs_to :commentable, polymorphic: true

  def self.ransackable_attributes(auth_object = nil)
    ["body", "created_at", "updated_at", "id", "user_id", "commentable_type", "commentable_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user"]
  end

end
