require 'rails_helper'

RSpec.describe 'Comments', type: :request do
  describe 'POST /courses/:course_id/comments' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course) }

    before do
      sign_in user
    end

    it 'creates a course comment and redirects to the course comments section' do
      expect do
        post course_comments_path(course), params: { comment: { body: 'This is a valid web course comment.' } }
      end.to change(Comment, :count).by(1)

      expect(response).to redirect_to(course_path(course, anchor: 'comments-section'))
      expect(flash[:notice]).to eq('Comment added successfully.')
    end

    it 'redirects with an error when the comment is invalid' do
      post course_comments_path(course), params: { comment: { body: 'bad' } }

      expect(response).to redirect_to(course_path(course, anchor: 'comments-section'))
      expect(flash[:comment_error]).to be_present
    end
  end

  describe 'POST /courses/:course_id/lessons/:lesson_id/comments' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course) }
    let(:lesson) { create(:lesson, course: course) }

    before do
      sign_in user
    end

    it 'creates a lesson comment and redirects to the lesson comments section' do
      expect do
        post course_lesson_comments_path(course, lesson), params: { comment: { body: 'This is a valid lesson comment.' } }
      end.to change(Comment, :count).by(1)

      expect(response).to redirect_to(course_lesson_path(course, lesson, anchor: 'comments-section'))
      expect(flash[:notice]).to eq('Comment added successfully.')
    end
  end

  describe 'GET /courses/:course_id/comments/:id/edit' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course) }
    let(:comment) { Comment.create!(user: author, commentable: course, body: 'Editable web comment body.') }

    it 'shows the edit page for the comment owner' do
      sign_in author

      get edit_course_comment_path(course, comment)

      expect(response).to have_http_status(:ok)
    end

    it 'redirects non-owners to root' do
      other_user = create(:user, :with_profile)
      sign_in other_user

      get edit_course_comment_path(course, comment)

      expect(response).to redirect_to(root_path)
    end
  end

  describe 'PATCH /courses/:course_id/comments/:id' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course) }
    let(:comment) { Comment.create!(user: author, commentable: course, body: 'Original comment body.') }

    before do
      sign_in author
    end

    it 'updates the comment and redirects to the course comments section' do
      patch course_comment_path(course, comment), params: { comment: { body: 'Updated web comment body.' } }

      expect(response).to redirect_to(course_path(course, anchor: 'comments-section'))
      expect(flash[:notice]).to eq('Comment updated successfully.')
      expect(comment.reload.body).to eq('Updated web comment body.')
    end
  end

  describe 'DELETE /courses/:course_id/comments/:id' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course) }
    let(:comment) { Comment.create!(user: author, commentable: course, body: 'Comment body to delete.') }

    before do
      sign_in author
    end

    it 'deletes the comment and redirects to the course comments section' do
      comment

      expect do
        delete course_comment_path(course, comment)
      end.to change(Comment, :count).by(-1)

      expect(response).to redirect_to(course_path(course, anchor: 'comments-section'))
      expect(flash[:notice]).to eq('Comment deleted successfully.')
    end
  end
end