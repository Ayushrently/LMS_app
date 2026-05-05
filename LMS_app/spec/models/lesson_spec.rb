# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson, type: :model do
  subject(:lesson) { create(:lesson) }

  context 'Relationships' do
    it { should belong_to(:course) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
  end

  context 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_least(5).is_at_most(20) }
    it { should validate_uniqueness_of(:title).scoped_to(:course_id) }
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_least(20) }
  end

  describe '.preprocess_data' do
    it 'strips leading and trailing whitespace from title and content' do
      lesson = build(:lesson, title: '  Sample Title  ',
                              content: '  This lesson content is long enough to satisfy validation.  ')
      lesson.valid? # Trigger validations and callbacks
      expect(lesson.title).to eq('Sample Title')
      expect(lesson.content).to eq('This lesson content is long enough to satisfy validation.')
    end
  end

  describe '.includes ransackable attributes' do
    it('includes only the specified attributes') do
      expect(Lesson.ransackable_attributes).to match_array(%w[title content created_at id course_id])
    end
  end

  describe '.includes ransackable associations' do
    it('includes only the specified associations') do
      expect(Lesson.ransackable_associations).to match_array(['course'])
    end
  end
end
