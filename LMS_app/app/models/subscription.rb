class Subscription < ApplicationRecord

  enum plan_name: { basic: "basic", pro: "pro" }, _default: :basic

  validates :plan_name, presence:true

  belongs_to :profile

  def self.ransackable_attributes(auth_object = nil)
    ["plan_name", "created_at", "updated_at", "id", "profile_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["profile"]
  end

end
