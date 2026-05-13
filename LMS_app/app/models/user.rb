# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :profile, dependent: :destroy
  has_one :subscription, through: :profile, dependent: :destroy
  has_many :comments
  has_many :enrollments, dependent: :destroy
  has_many :courses, through: :enrollments
  has_and_belongs_to_many :authored_courses, class_name: 'Course', join_table: :courses_users

  def self.ransackable_attributes(_auth_object = nil)
    %w[id email created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[profile comments enrollments courses authored_courses subscription]
  end
end
