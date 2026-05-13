# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Enrollments', type: :request do
  def json_response
    response.parsed_body
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

    context 'when course id does not exist' do
      before do
        post '/api/v1/courses/999_999/enrollment', headers: auth_headers_for(user)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when enrolling in a free course' do
      it 'creates an enrollment and returns created', :aggregate_failures do
        expect { perform_request }.to change(Enrollment, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json_response['message']).to eq('Enrolled successfully')
      end
    end

    context 'when enrolling in a pro course' do
      let(:pro_course) { create(:course, :pro) }

      it 'rejects enrollment without a pro subscription', :aggregate_failures do
        post "/api/v1/courses/#{pro_course.id}/enrollment", headers: auth_headers_for(user)

        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('You need a Pro subscription to enroll in this course')
      end

      it 'allows enrollment with a pro subscription' do
        pro_user = create(:user, :with_profile)
        create(:subscription, profile: pro_user.profile, plan_name: 'pro')

        expect do
          post "/api/v1/courses/#{pro_course.id}/enrollment", headers: auth_headers_for(pro_user)
        end.to change(Enrollment, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'when user is already enrolled' do
      before do
        allow_any_instance_of(Enrollment).to receive(:save).and_raise(ActiveRecord::RecordInvalid.new(Enrollment.new))
        perform_request
      end
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

    context 'when course id does not exist' do
      before do
        delete '/api/v1/courses/999_999/enrollment', headers: auth_headers_for(user)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when enrollment destruction fails' do
      before do
        allow_any_instance_of(Enrollment).to receive(:destroy).and_return(false)
        perform_request
      end

      it 'returns unprocessable entity with error', :aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to eq('Failed to unenroll')
      end
    end

    context 'when request user has no enrollment' do
      let(:other_user) { create(:user, :with_profile) }

      before do
        delete path, headers: auth_headers_for(other_user)
      end

      it 'returns not found enrollment error', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Enrollment not found')
      end
    end

    context 'when request user is course author' do
      let(:author) { create(:user, :with_profile) }
      let(:author_course) { create(:course, creator: author.profile.username) }

      before do
        author_course.authors << author
        delete "/api/v1/courses/#{author_course.id}/enrollment", headers: auth_headers_for(author)
      end

      it 'forbids unenrolling from own course', :aggregate_failures do
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Authors cannot unenroll from their own course')
      end
    end

    context 'when request is valid' do
      it 'deletes enrollment and returns no content', :aggregate_failures do
        expect { perform_request }.to change(Enrollment, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
