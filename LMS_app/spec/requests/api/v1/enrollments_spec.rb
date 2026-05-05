require 'rails_helper'

RSpec.describe 'API V1 Enrollments', type: :request do
  def json_response
    JSON.parse(response.body)
  end

  describe 'POST /api/v1/courses/:course_id/enrollment' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course, tier: 'free') }
    let(:path) { "/api/v1/courses/#{course.id}/enrollment" }

    subject(:perform_request) { post path, headers: auth_headers_for(user) }

    it 'returns unauthorized without a bearer token' do
      post path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns not found for a missing course id' do
      post '/api/v1/courses/999_999/enrollment', headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'allows enrollment into a free course' do
      expect { perform_request }.to change(Enrollment, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['message']).to eq('Enrolled successfully')
    end

    it 'rejects enrollment into a pro course without a pro subscription' do
      pro_course = create(:course, :pro)

      post "/api/v1/courses/#{pro_course.id}/enrollment", headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('You need a Pro subscription to enroll in this course')
    end

    it 'allows enrollment into a pro course with a pro subscription' do
      pro_user = create(:user, :with_profile)
      create(:subscription, profile: pro_user.profile, plan_name: 'pro')
      pro_course = create(:course, :pro)

      expect do
        post "/api/v1/courses/#{pro_course.id}/enrollment", headers: auth_headers_for(pro_user)
      end.to change(Enrollment, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it 'returns unprocessable entity when already enrolled' do
      create(:enrollment, user: user, course: course)

      perform_request

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to be_present
    end
  end

  describe 'DELETE /api/v1/courses/:course_id/enrollment' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course, tier: 'free', creator: 'another_author') }
    let(:path) { "/api/v1/courses/#{course.id}/enrollment" }

    subject(:perform_request) do
      delete path, headers: auth_headers_for(user)
    end

    before do
      create(:enrollment, user: user, course: course)
    end

    it 'returns unauthorized without a bearer token' do
      delete path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns not found for a missing course id' do
      delete '/api/v1/courses/999_999/enrollment', headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'returns an error when destruction fails' do
      # We find the instance and force it to return false
      allow_any_instance_of(Enrollment).to receive(:destroy).and_return(false)
      perform_request

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to eq('Failed to unenroll')
    end

    it 'returns not found when the user has no enrollment to delete' do
      other_user = create(:user, :with_profile)

      delete path, headers: auth_headers_for(other_user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Enrollment not found')
    end

    it 'prevents authors from unenrolling from their own course' do
      author = create(:user, :with_profile)
      author_course = create(:course, creator: author.profile.username)
      author_course.authors << author

      delete "/api/v1/courses/#{author_course.id}/enrollment", headers: auth_headers_for(author)

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Authors cannot unenroll from their own course')
    end

    it 'allows a regular enrolled user to unenroll' do
      expect { perform_request }.to change(Enrollment, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
