class Profile < ApplicationRecord
  validates :name, :username, presence: true, length: { in: 3..20 }
  validates :bio, length: { maximum: 500 }
  validates :username, uniqueness: true

  belongs_to :user
  has_one :subscription
end
