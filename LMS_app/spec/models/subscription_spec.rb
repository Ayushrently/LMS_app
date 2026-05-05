#

require 'rails_helper'

RSpec.describe Subscription, type: :model do
  subject(:subscription) { create(:subscription) }

  context 'Relationships' do
    it { should belong_to(:profile) }
  end

  describe '.includes ransackable attributes' do
    it('includes only the specified attributes') do
      expect(Subscription.ransackable_attributes).to match_array(%w[
                                                                   plan_name
                                                                   created_at
                                                                   updated_at
                                                                   id
                                                                   profile_id
                                                                 ])
    end
  end

  describe '.includes ransackable associations' do
    it('includes only the specified associations') do
      expect(Subscription.ransackable_associations).to match_array(%w[profile])
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:plan_name) }
  end
end
