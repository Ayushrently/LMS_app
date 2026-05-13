# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Profile, type: :model do
  subject(:profile) { create(:profile) }

  context 'relationships' do
    it { should belong_to(:user) }
    it { should have_one(:subscription).dependent(:destroy) }
  end

  describe '.includes ransackable attributes' do
    it('includes only the specified attributes') do
      expect(Profile.ransackable_attributes).to match_array(%w[
                                                              name
                                                              username
                                                              bio
                                                              created_at
                                                              updated_at
                                                              id
                                                              user_id
                                                            ])
    end
  end

  describe '.includes ransackable associations' do
    it('includes only the specified associations') do
      expect(Profile.ransackable_associations).to match_array(%w[subscription user])
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:username) }
    it { should validate_length_of(:name).is_at_least(3).is_at_most(20) }
    it { should validate_length_of(:bio).is_at_most(500) }
    it { should accept_nested_attributes_for(:subscription).update_only(true) }
  end
end
