# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Enrollment, type: :model do
  subject(:enrollment) { create(:enrollment) }

  context 'Relationships' do
    it { should belong_to(:user) }
    it { should belong_to(:course) }
  end

  describe '.includes ransackable attributes' do
    it('includes only the specified attributes') do
      expect(Enrollment.ransackable_attributes).to match_array(%w[
                                                                 course_id
                                                                 user_id
                                                                 created_at
                                                                 updated_at
                                                                 id
                                                               ])
    end
  end

  describe '.includes ransackable associations' do
    it('includes only the specified associations') do
      expect(Enrollment.ransackable_associations).to match_array(%w[course user])
    end
  end

  describe 'validations' do
    it { should validate_uniqueness_of(:user_id).scoped_to(:course_id) }
  end
end
