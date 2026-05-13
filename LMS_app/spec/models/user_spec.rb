# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  context 'relationships' do
    it { should have_one(:profile).dependent(:destroy) }
    it { should have_one(:subscription).through(:profile).dependent(:destroy) }
    it { should have_many(:comments) }
    it { should have_many(:enrollments).dependent(:destroy) }
    it { should have_many(:courses).through(:enrollments) }
    it { should have_and_belong_to_many(:authored_courses).class_name('Course').join_table(:courses_users) }
  end

  describe '.includes ransackable attributes' do
    it('includes only the specified attributes') do
      expect(User.ransackable_attributes).to match_array(%w[id email created_at updated_at])
    end
  end

  describe '.includes ransackable associations' do
    it('includes only the specified associations') do
      expect(User.ransackable_associations).to match_array(%w[profile comments enrollments courses
                                                              authored_courses subscription])
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }
  end

  describe 'user details' do
    it 'authenticates with valid credentials', :aggregate_failures do
      user = User.create(
        email: 'someonttte@gmail.com',
        password: 'password123',
        password_confirmation: 'password123'
      )

      expect(user.valid_password?('password123')).to be(true)
      expect(user.valid_password?('wrongpassword')).to be(false)
    end
  end
end
