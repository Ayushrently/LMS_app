# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Lessons', type: :request do
  describe 'GET /courses/:course_id/lessons/:id' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course) }
    let(:lesson) { create(:lesson, course: course) }

    before do
      sign_in user
    end

    it 'redirects to the course when the user is not enrolled' do
      get course_lesson_path(course, lesson)

      expect(response).to redirect_to(course_path(course))
    end

    it 'shows the lesson when the user is enrolled' do
      create(:enrollment, user: user, course: course)

      get course_lesson_path(course, lesson)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /courses/:course_id/lessons' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course) }

    before do
      sign_in user
    end

    it 'creates a lesson and redirects to the course edit page' do
      expect do
        post course_lessons_path(course), params: {
          lesson: {
            course_id: course.id,
            title: 'Fresh Lesson',
            content: 'Lesson content that is definitely long enough.'
          }
        }
      end.to change(Lesson, :count).by(1)

      expect(response).to redirect_to(edit_course_path(course))
    end

    it 'returns unprocessable entity for invalid params' do
      post course_lessons_path(course), params: {
        lesson: {
          course_id: course.id,
          title: 'bad',
          content: 'short'
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /courses/:course_id/lessons/:id/edit' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }
    let(:lesson) { create(:lesson, course: course) }

    before do
      course.authors << author
    end

    it 'redirects non-authors to the course page' do
      non_author = create(:user, :with_profile)
      sign_in non_author

      get edit_course_lesson_path(course, lesson)

      expect(response).to redirect_to(course_path(course))
    end

    it 'shows the edit page for authors' do
      sign_in author

      get edit_course_lesson_path(course, lesson)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /courses/:course_id/lessons/:id' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }
    let(:lesson) { create(:lesson, course: course) }

    before do
      course.authors << author
    end

    it 'redirects non-authors to the course page' do
      non_author = create(:user, :with_profile)
      sign_in non_author

      patch course_lesson_path(course, lesson), params: { lesson: { title: 'Blocked Update' } }

      expect(response).to redirect_to(course_path(course))
    end

    it 'updates the lesson for authors' do
      sign_in author

      patch course_lesson_path(course, lesson), params: { lesson: { title: 'Updated Web Lesson' } }

      expect(response).to redirect_to(edit_course_path(course))
      expect(lesson.reload.title).to eq('Updated Web Lesson')
    end
  end
end
