require 'rails_helper'

RSpec.describe 'API V1 Comments', type: :request do
  def json_response
    response.parsed_body
  end

  describe 'POST /api/v1/courses/:course_id/comments' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course) }
    let(:path) { "/api/v1/courses/#{course.id}/comments" }
    let(:params) { { comment: { body: 'This is a valid course comment.' } } }

    subject(:perform_request) { post path, params: params, headers: auth_headers_for(user) }

    it 'returns unauthorized without a bearer token' do
      post path, params: params

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns not found for a missing course id' do
      post '/api/v1/courses/999_999/comments',
           params: params,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'creates a course comment for an authenticated user' do
      expect { perform_request }.to change(Comment, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['commentable_type']).to eq('Course')
      expect(json_response['user_id']).to eq(user.id)
    end

    it 'returns unprocessable entity for invalid comment body' do
      post path,
           params: { comment: { body: 'hi' } },
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to be_present
    end
  end

  describe 'POST /api/v1/courses/:course_id/lessons/:lesson_id/comments' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course) }
    let(:lesson) { create(:lesson, course: course) }
    let(:path) { "/api/v1/courses/#{course.id}/lessons/#{lesson.id}/comments" }
    let(:params) { { comment: { body: 'This is a valid lesson comment body.' } } }

    subject(:perform_request) { post path, params: params, headers: auth_headers_for(user) }

    it 'returns unauthorized without a bearer token' do
      post path, params: params

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns not found for a missing course id' do
      post "/api/v1/courses/999_999/lessons/#{lesson.id}/comments",
           params: params,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'returns not found for a missing lesson id' do
      post "/api/v1/courses/#{course.id}/lessons/999999/comments",
           params: params,
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Commentable not found')
    end

    it 'forbids lesson comments when the user is not enrolled' do
      perform_request

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('You must be enrolled in the course to comment on this lesson')
    end

    it 'creates a lesson comment for an enrolled user' do
      create(:enrollment, user: user, course: course)

      expect { perform_request }.to change(Comment, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['commentable_type']).to eq('Lesson')
      expect(json_response['user_id']).to eq(user.id)
    end
  end

  describe 'GET /api/v1/courses/:course_id/comments/:id' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course) }
    let(:comment) { Comment.create!(user: user, commentable: course, body: 'A readable comment body.') }
    let(:path) { "/api/v1/courses/#{course.id}/comments/#{comment.id}" }

    subject(:perform_request) { get path, headers: auth_headers_for(user) }

    it 'returns unauthorized without a bearer token' do
      get path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns not found for a missing course id' do
      get "/api/v1/courses/999_999/comments/#{comment.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'returns not found for a missing comment id' do
      get "/api/v1/courses/#{course.id}/comments/999_999", headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Comment not found')
    end

    it 'returns the comment for an authenticated user' do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(json_response['id']).to eq(comment.id)
      expect(json_response['body']).to eq(comment.body)
    end
  end

  describe 'PATCH /api/v1/courses/:course_id/comments/:id' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course) }
    let(:comment) { Comment.create!(user: author, commentable: course, body: 'Original body for editing') }
    let(:path) { "/api/v1/courses/#{course.id}/comments/#{comment.id}" }
    let(:params) { { comment: { body: 'Updated body that is long enough.' } } }

    subject(:perform_request) { patch path, params: params, headers: auth_headers_for(author) }

    it 'returns unauthorized without a bearer token' do
      patch path, params: params

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns not found for a missing course id' do
      patch "/api/v1/courses/999_999/comments/#{comment.id}",
            params: params,
            headers: auth_headers_for(author)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'returns not found for a missing comment id' do
      patch "/api/v1/courses/#{course.id}/comments/999_999",
            params: params,
            headers: auth_headers_for(author)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Comment not found')
    end

    it 'rejects updates from users who do not own the comment' do
      other_user = create(:user, :with_profile)

      patch path,
            params: params,
            headers: auth_headers_for(other_user)

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Not the author of the comment')
    end

    it 'updates the comment for the comment owner' do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(comment.reload.body).to eq('Updated body that is long enough.')
    end

    it 'returns unprocessable entity for invalid update body' do
      patch path,
            params: { comment: { body: 'bad' } },
            headers: auth_headers_for(author)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to be_present
    end
  end

  describe 'DELETE /api/v1/courses/:course_id/comments/:id' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course) }
    let(:comment) { Comment.create!(user: author, commentable: course, body: 'A deletable comment body.') }
    let(:path) { "/api/v1/courses/#{course.id}/comments/#{comment.id}" }

    subject(:perform_request) { delete path, headers: auth_headers_for(author) }

    it 'returns unauthorized without a bearer token' do
      delete path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns not found for a missing course id' do
      delete "/api/v1/courses/999_999/comments/#{comment.id}", headers: auth_headers_for(author)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'returns not found for a missing comment id' do
      delete "/api/v1/courses/#{course.id}/comments/999_999", headers: auth_headers_for(author)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Comment not found')
    end

    it 'returns an error when destruction fails' do
      allow_any_instance_of(Comment).to receive(:destroy).and_return(false)
      perform_request

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to eq('Failed to delete comment')
    end

    it 'rejects deletion by users who do not own the comment' do
      other_user = create(:user, :with_profile)

      delete path, headers: auth_headers_for(other_user)

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Not the author of the comment')
    end

    it 'deletes the comment for the comment owner' do
      comment

      expect { perform_request }.to change(Comment, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
