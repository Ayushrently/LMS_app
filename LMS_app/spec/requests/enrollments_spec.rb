require 'rails_helper'

RSpec.describe 'Enrollments', type: :request do
  describe 'POST /courses/:course_id/enrollments' do
    let(:user) { create(:user, :with_profile) }

    before do
      sign_in user
    end

    it 'enrolls the user in a free course' do
      course = create(:course, tier: 'free')

      expect do
        post course_enrollments_path(course)
      end.to change(Enrollment, :count).by(1)

      expect(response).to redirect_to(course_path(course))
      expect(flash[:notice]).to eq('Successfully enrolled in course.')
    end

    it 'rejects pro enrollment without a pro subscription' do
      course = create(:course, tier: 'pro')

      post course_enrollments_path(course)

      expect(response).to redirect_to(course_path(course))
      expect(flash[:alert]).to eq('You need a Pro subscription to enroll in this course.')
    end

    it 'redirects with an alert when the enrollment cannot be created' do
      course = create(:course, tier: 'free')
      create(:enrollment, user: user, course: course)

      post course_enrollments_path(course)

      expect(response).to redirect_to(course_path(course))
      expect(flash[:alert]).to eq('Unable to enroll. Please try again.')
    end
  end

  describe 'DELETE /courses/:course_id/enrollments/:id' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course, tier: 'free') }

    before do
      sign_in user
    end

    it 'unenrolls the current user and redirects to courses index' do
      enrollment = create(:enrollment, user: user, course: course)

      expect do
        delete course_enrollment_path(course, enrollment)
      end.to change(Enrollment, :count).by(-1)

      expect(response).to redirect_to(courses_path(course))
    end

    it 'redirects back to the course when no enrollment is found' do
      delete course_enrollment_path(course, 999_999)

      expect(response).to redirect_to(course_path(course))
    end
  end
end