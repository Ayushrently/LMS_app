# frozen_string_literal: true

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

    context 'when course id does not exist' do
      before do
        post '/api/v1/courses/999_999/comments',
             params: params,
             headers: auth_headers_for(user)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when request is valid' do
      it 'creates a course comment with expected attributes', :aggregate_failures do
        expect { perform_request }.to change(Comment, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json_response['commentable_type']).to eq('Course')
        expect(json_response['user_id']).to eq(user.id)
      end
    end

    context 'when comment body is invalid' do
      before do
        post path,
             params: { comment: { body: 'hi' } },
             headers: auth_headers_for(user)
      end

      it 'returns unprocessable entity with errors', :aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to be_present
      end
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

    context 'when course id does not exist' do
      before do
        post "/api/v1/courses/999_999/lessons/#{lesson.id}/comments",
             params: params,
             headers: auth_headers_for(user)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when lesson id does not exist' do
      before do
        post "/api/v1/courses/#{course.id}/lessons/999999/comments",
             params: params,
             headers: auth_headers_for(user)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Commentable not found')
      end
    end

    context 'when user is not enrolled' do
      before { perform_request }

      it 'returns forbidden with enrollment error', :aggregate_failures do
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('You must be enrolled in the course to comment on this lesson')
      end
    end

    context 'when user is enrolled' do
      before do
        create(:enrollment, user: user, course: course)
      end

      it 'creates a lesson comment with expected attributes', :aggregate_failures do
        expect { perform_request }.to change(Comment, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json_response['commentable_type']).to eq('Lesson')
        expect(json_response['user_id']).to eq(user.id)
      end
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

    context 'when course id does not exist' do
      before do
        get "/api/v1/courses/999_999/comments/#{comment.id}", headers: auth_headers_for(user)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when comment id does not exist' do
      before do
        get "/api/v1/courses/#{course.id}/comments/999_999", headers: auth_headers_for(user)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Comment not found')
      end
    end

    context 'when request is valid' do
      before { perform_request }

      it 'returns the requested comment payload', :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(json_response['id']).to eq(comment.id)
        expect(json_response['body']).to eq(comment.body)
      end
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

    context 'when course id does not exist' do
      before do
        patch "/api/v1/courses/999_999/comments/#{comment.id}",
              params: params,
              headers: auth_headers_for(author)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when comment id does not exist' do
      before do
        patch "/api/v1/courses/#{course.id}/comments/999_999",
              params: params,
              headers: auth_headers_for(author)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Comment not found')
      end
    end

    context 'when requester is not comment author' do
      let(:other_user) { create(:user, :with_profile) }

      before do
        patch path,
              params: params,
              headers: auth_headers_for(other_user)
      end

      it 'returns unauthorized with author error', :aggregate_failures do
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Not the author of the comment')
      end
    end

    context 'when request is valid' do
      before { perform_request }

      it 'updates the comment body', :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(comment.reload.body).to eq('Updated body that is long enough.')
      end
    end

    context 'when update params are invalid' do
      before do
        patch path,
              params: { comment: { body: 'bad' } },
              headers: auth_headers_for(author)
      end

      it 'returns unprocessable entity with errors', :aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to be_present
      end
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

    context 'when course id does not exist' do
      before do
        delete "/api/v1/courses/999_999/comments/#{comment.id}", headers: auth_headers_for(author)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when comment id does not exist' do
      before do
        delete "/api/v1/courses/#{course.id}/comments/999_999", headers: auth_headers_for(author)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Comment not found')
      end
    end

    context 'when comment destruction fails' do
      before do
        allow_any_instance_of(Comment).to receive(:destroy).and_return(false)
        perform_request
      end

      it 'returns unprocessable entity with errors', :aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to eq('Failed to delete comment')
      end
    end

    context 'when requester is not comment author' do
      let(:other_user) { create(:user, :with_profile) }

      before do
        delete path, headers: auth_headers_for(other_user)
      end

      it 'returns unauthorized with author error', :aggregate_failures do
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Not the author of the comment')
      end
    end

    context 'when request is valid' do
      before { comment }

      it 'deletes the comment and returns no content', :aggregate_failures do
        expect { perform_request }.to change(Comment, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
