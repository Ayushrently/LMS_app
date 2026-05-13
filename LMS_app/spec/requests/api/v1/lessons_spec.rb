# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Lessons', type: :request do
  def json_response
    response.parsed_body
  end

  def lesson_payload(title: 'New Title', content: 'This content is long enough for the validation rule.')
    { title: title, content: content }
  end

  describe 'GET /api/v1/courses/:course_id/lessons' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course) }
    let(:path) { "/api/v1/courses/#{course.id}/lessons" }

    subject(:perform_request) { get path, headers: auth_headers_for(user) }

    it 'returns unauthorized without a bearer token' do
      get path

      expect(response).to have_http_status(:unauthorized)
    end

    context 'when course id does not exist' do
      before do
        get '/api/v1/courses/999_999/lessons', headers: auth_headers_for(user)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when request is valid' do
      let!(:lesson_one) { create(:lesson, course: course, title: 'Lesson One') }
      let!(:lesson_two) { create(:lesson, course: course, title: 'Lesson Two') }

      before { perform_request }

      it 'returns lessons and pagination metadata', :aggregate_failures do
        expect(response).to have_http_status(:ok)
        ids = json_response['lessons'].pluck('id')
        expect(ids).to include(lesson_one.id, lesson_two.id)
        expect(json_response['pagination']).to include('current_page', 'total_pages', 'total_count')
      end
    end
  end

  describe 'GET /api/v1/courses/:course_id/lessons/:id' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course) }
    let(:lesson) { create(:lesson, course: course) }
    let(:path) { "/api/v1/courses/#{course.id}/lessons/#{lesson.id}" }

    subject(:perform_request) { get path, headers: auth_headers_for(user) }

    it 'returns unauthorized without a bearer token' do
      get path

      expect(response).to have_http_status(:unauthorized)
    end

    context 'when course id does not exist' do
      before do
        get "/api/v1/courses/999_999/lessons/#{lesson.id}", headers: auth_headers_for(user)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when lesson id does not exist' do
      before do
        create(:enrollment, user: user, course: course)
        get "/api/v1/courses/#{course.id}/lessons/999_999", headers: auth_headers_for(user)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Lesson not found')
      end
    end

    context 'when user is not enrolled' do
      before { perform_request }

      it 'returns forbidden with enrollment error', :aggregate_failures do
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('You must be enrolled to view this lesson')
      end
    end

    context 'when user is enrolled' do
      before do
        create(:enrollment, user: user, course: course)
        perform_request
      end

      it 'returns lesson payload', :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(json_response.dig('lesson', 'id')).to eq(lesson.id)
      end
    end
  end

  describe 'POST /api/v1/courses/:course_id/lessons' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }
    let(:path) { "/api/v1/courses/#{course.id}/lessons" }
    let(:params) { { lesson: lesson_payload } }

    subject(:perform_request) { post path, params: params, headers: auth_headers_for(author) }

    before do
      course.authors << author
    end

    it 'returns unauthorized without a bearer token' do
      post path, params: params

      expect(response).to have_http_status(:unauthorized)
    end

    context 'when course id does not exist' do
      before do
        post '/api/v1/courses/999_999/lessons',
             params: params,
             headers: auth_headers_for(author)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when requester is not author' do
      let(:user) { create(:user, :with_profile) }

      before do
        post path,
             params: params,
             headers: auth_headers_for(user)
      end

      it 'returns forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when request is valid' do
      it 'creates lesson and returns created', :aggregate_failures do
        expect { perform_request }.to change(course.lessons, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end

    context 'when lesson params are invalid' do
      before do
        post path,
             params: { lesson: lesson_payload(title: 'abc', content: 'short') },
             headers: auth_headers_for(author)
      end

      it 'returns unprocessable entity with errors', :aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to be_present
      end
    end

    context 'when lesson key is missing' do
      before do
        post path,
             params: { title: 'No wrapper key' },
             headers: auth_headers_for(author)
      end

      it 'returns internal server error with payload error', :aggregate_failures do
        expect(response).to have_http_status(:internal_server_error)
        expect(json_response['error']).to be_present
      end
    end
  end

  describe 'PATCH /api/v1/courses/:course_id/lessons/:id' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }
    let(:lesson) { create(:lesson, course: course) }
    let(:path) { "/api/v1/courses/#{course.id}/lessons/#{lesson.id}" }
    let(:params) { { lesson: { title: 'Updated Title' } } }

    subject(:perform_request) { patch path, params: params, headers: auth_headers_for(author) }

    before do
      course.authors << author
    end

    it 'returns unauthorized without a bearer token' do
      patch path, params: params

      expect(response).to have_http_status(:unauthorized)
    end

    context 'when course id does not exist' do
      before do
        patch "/api/v1/courses/999_999/lessons/#{lesson.id}",
              params: params,
              headers: auth_headers_for(author)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when lesson id does not exist' do
      before do
        patch "/api/v1/courses/#{course.id}/lessons/999_999",
              params: params,
              headers: auth_headers_for(author)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Lesson not found')
      end
    end

    context 'when requester is not author' do
      let(:non_author) { create(:user, :with_profile) }

      before do
        patch path,
              params: params,
              headers: auth_headers_for(non_author)
      end

      it 'returns forbidden with author error', :aggregate_failures do
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('You must be an author to perform this action')
      end
    end

    context 'when request is valid' do
      before { perform_request }

      it 'updates lesson and returns ok', :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(lesson.reload.title).to eq('Updated Title')
      end
    end

    context 'when update params are invalid' do
      before do
        patch path,
              params: { lesson: { title: 'bad', content: 'short' } },
              headers: auth_headers_for(author)
      end

      it 'returns unprocessable entity with errors', :aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to be_present
      end
    end
  end
end
