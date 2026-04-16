class Profile < ApplicationRecord
  validates :name, :username, presence: true, length: { in: 3..20 }
  validates :bio, length: { maximum: 500 }
  validates :username, uniqueness: true

  belongs_to :user
  has_one :subscription, dependent: :destroy, inverse_of: :profile

  accepts_nested_attributes_for :subscription, update_only: true
end
