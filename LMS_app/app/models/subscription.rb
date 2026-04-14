class Subscription < ApplicationRecord
  validates :plan_name, presence:true, length:{ in: 2..20 }

  belongs_to :profile
end
