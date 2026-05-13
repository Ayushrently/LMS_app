# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment, type: :model do
  context 'relationships' do
    it { should belong_to(:user) }
    it { should belong_to(:commentable) }
  end

  describe '.includes ransackable attributes' do
    it('includes only the specified attributes') do
      expect(Comment.ransackable_attributes).to match_array(%w[body created_at updated_at id user_id
                                                               commentable_type commentable_id])
    end
  end

  describe '.includes ransackable associations' do
    it('includes only the specified associations') do
      expect(Comment.ransackable_associations).to match_array(['user'])
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:body) }
    it { should validate_length_of(:body).is_at_least(5).is_at_most(1000) }
  end
end
