# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Course, type: :model do
  subject(:course) { create(:course) }

  context 'relationships' do
    it { should have_many(:enrollments).dependent(:destroy) }
    it { should have_many(:users).through(:enrollments) }
    it { should have_many(:lessons).dependent(:destroy) }
    it { should have_and_belong_to_many(:authors).class_name('User').join_table('courses_users') }
    it { should have_many(:comments).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:description) }
    it { should validate_length_of(:title).is_at_least(5).is_at_most(100) }
    it { should validate_uniqueness_of(:title).case_insensitive }
    it { should validate_length_of(:description).is_at_least(10).is_at_most(600) }
  end

  describe 'enums' do
    it 'defaults to free tier' do
      expect(build(:course).tier).to eq('free')
    end

    it 'supports pro tier' do
      expect(build(:course, :pro)).to be_pro
    end
  end

  describe 'default_scope' do
    it 'returns courses without deleted_at' do
      default_course = create(:course)
      soft_deleted_course = create(:course, deleted_at: Time.current)

      expect(described_class.where(id: [default_course.id, soft_deleted_course.id]))
        .to contain_exactly(default_course)
    end
  end

  describe '.soft_deleted' do
    it 'returns courses with deleted_at set' do
      soft_deleted_course = create(:course, deleted_at: Time.current)
      active_course = create(:course)

      expect(described_class.unscoped.soft_deleted.where(id: [soft_deleted_course.id, active_course.id]))
        .to contain_exactly(soft_deleted_course)
    end
  end

  describe '#soft_deleted?' do
    it 'is true when deleted_at is present' do
      expect(build(:course, deleted_at: Time.current)).to be_soft_deleted
    end

    it 'is false when deleted_at is blank' do
      expect(build(:course, deleted_at: nil)).not_to be_soft_deleted
    end
  end

  describe '#soft_delete!' do
    it 'hard deletes the course when it has no enrollments' do
      deletable_course = create(:course)

      deletable_course.soft_delete!

      expect(described_class.unscoped.where(id: deletable_course.id)).to be_empty
    end

    it 'soft deletes the course and removes author enrollments when enrollments exist', :aggregate_failures do
      author = create(:user)
      learner = create(:user)
      course_with_author = create(:course)
      course_with_author.authors << author
      create(:enrollment, course: course_with_author, user: learner)

      course_with_author.soft_delete!

      expect(described_class.unscoped.find(course_with_author.id).deleted_at).to be_present
      expect(course_with_author.authors.reload).to be_empty
      expect(course_with_author.enrollments.where(user: author)).to be_empty
    end
  end

  describe 'author callbacks' do
    let(:author) { create(:user) }

    it 'creates an enrollment when an author is added' do
      expect { course.authors << author }
        .to change(course.enrollments, :count).by(1)

      expect(course.enrollments.find_by(user: author)).to be_present
    end

    it 'blocks duplicate authors' do
      course.authors << author

      expect { course.authors << author }
        .not_to change(course.authors, :count)

      expect(course.errors[:authors]).to include('already includes this user')
    end

    it "removes the author's enrollment when an author is removed" do
      course.authors << author

      expect { course.authors.destroy(author) }
        .to change(course.enrollments, :count).by(-1)

      expect(course.authors.reload).to be_empty
    end

    it 'prevents removing the creator when creator matches the profile username' do
      creator = create(:user)
      create(:profile, user: creator, username: 'course-creator', name: 'Other Name')
      created_course = create(:course, creator: 'course-creator')
      created_course.authors << creator

      expect { created_course.authors.destroy(creator) }
        .not_to change(created_course.authors, :count)

      expect(created_course.errors[:authors]).to include('cannot remove course creator')
    end
  end

  describe '.ransackable_associations' do
    it 'returns the supported associations' do
      expect(described_class.ransackable_associations)
        .to match_array(%w[enrollments authors users])
    end
  end

  describe '.ransackable_attributes' do
    it 'returns the supported attributes' do
      expect(described_class.ransackable_attributes)
        .to match_array(%w[id title description tier creator created_at updated_at deleted_at])
    end
  end
end
