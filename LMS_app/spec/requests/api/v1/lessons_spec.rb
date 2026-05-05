require 'rails_helper'

RSpec.describe 'API V1 Lessons', type: :request do
  def json_response
    JSON.parse(response.body)
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

    it 'returns not found for a missing course id' do
      get '/api/v1/courses/999_999/lessons', headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'returns paginated lessons for a valid course' do
      lesson_one = create(:lesson, course: course, title: 'Lesson One')
      lesson_two = create(:lesson, course: course, title: 'Lesson Two')

      perform_request

      expect(response).to have_http_status(:ok)
      ids = json_response['lessons'].map { |lesson| lesson['id'] }
      expect(ids).to include(lesson_one.id, lesson_two.id)
      expect(json_response['pagination']).to include('current_page', 'total_pages', 'total_count')
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

    it 'returns not found for a missing course id' do
      get "/api/v1/courses/999_999/lessons/#{lesson.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'returns not found for a missing lesson id' do
      create(:enrollment, user: user, course: course)

      get "/api/v1/courses/#{course.id}/lessons/999_999", headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Lesson not found')
    end

    it 'forbids access when the user is not enrolled in the course' do
      perform_request

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('You must be enrolled to view this lesson')
    end

    it 'returns the lesson when the user is enrolled' do
      create(:enrollment, user: user, course: course)

      perform_request

      expect(response).to have_http_status(:ok)
      expect(json_response.dig('lesson', 'id')).to eq(lesson.id)
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

    it 'returns not found for a missing course id' do
      post '/api/v1/courses/999_999/lessons',
           params: params,
           headers: auth_headers_for(author)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'forbids creation for non-authors' do
      user = create(:user, :with_profile)

      post path,
           params: params,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end

    it 'creates a lesson for a course author' do
      expect { perform_request }.to change(course.lessons, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it 'returns unprocessable entity for invalid lesson params' do
      post path,
           params: { lesson: lesson_payload(title: 'abc', content: 'short') },
           headers: auth_headers_for(author)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to be_present
    end

    it 'returns internal server error when lesson key is missing' do
      post path,
           params: { title: 'No wrapper key' },
           headers: auth_headers_for(author)

      expect(response).to have_http_status(:internal_server_error)
      expect(json_response['error']).to be_present
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

    it 'returns not found for a missing course id' do
      patch "/api/v1/courses/999_999/lessons/#{lesson.id}",
            params: params,
            headers: auth_headers_for(author)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'returns not found for a missing lesson id' do
      patch "/api/v1/courses/#{course.id}/lessons/999_999",
            params: params,
            headers: auth_headers_for(author)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Lesson not found')
    end

    it 'forbids updates for non-authors' do
      non_author = create(:user, :with_profile)

      patch path,
            params: params,
            headers: auth_headers_for(non_author)

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('You must be an author to perform this action')
    end

    it 'updates a lesson for an author' do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(lesson.reload.title).to eq('Updated Title')
    end

    it 'returns unprocessable entity for invalid update params' do
      patch path,
            params: { lesson: { title: 'bad', content: 'short' } },
            headers: auth_headers_for(author)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to be_present
    end
  end
end
