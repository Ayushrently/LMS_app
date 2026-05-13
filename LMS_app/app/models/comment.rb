# frozen_string_literal: true

class Comment < ApplicationRecord
  validates :body, presence: true, length: { in: 5..1000 }

  belongs_to :user
  belongs_to :commentable, polymorphic: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[body created_at updated_at id user_id commentable_type commentable_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    ['user']
  end
end
