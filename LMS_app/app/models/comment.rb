class Comment < ApplicationRecord
  validates :body, presence:true, length: { in: 5..1000 }

  belongs_to :user
  belongs_to :commentable, polymorphic: true
end
