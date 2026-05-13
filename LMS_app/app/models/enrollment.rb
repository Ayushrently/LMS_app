# frozen_string_literal: true

class Enrollment < ApplicationRecord
  attr_accessor :username

  validates :user_id, uniqueness: { scope: :course_id }

  belongs_to :user
  belongs_to :course

  def self.ransackable_attributes(*)
    %w[course_id user_id created_at updated_at id]
  end

  def self.ransackable_associations(*)
    %w[course user]
  end
end
