class Subscription < ApplicationRecord
  enum :plan_name, { basic: 'basic', pro: 'pro' }, default: :basic

  validates :plan_name, presence: true

  belongs_to :profile

  def self.ransackable_attributes(*)
    %w[plan_name created_at updated_at id profile_id]
  end

  def self.ransackable_associations(*)
    ['profile']
  end
end
