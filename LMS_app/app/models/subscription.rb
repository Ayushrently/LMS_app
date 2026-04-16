class Subscription < ApplicationRecord

  enum plan_name: { basic: "basic", pro: "pro" }, _default: :basic

  validates :plan_name, presence:true

  belongs_to :profile
end
