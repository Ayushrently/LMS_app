# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Courses', type: :request do
  describe 'GET /courses' do
    context 'Authentication & access' do
      let(:user) { create(:user) }

      it 'redirects to sign in when the user is not authenticated' do
        get courses_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects users without a profile to the profile form' do
        sign_in user
        get courses_path
        expect(response).to redirect_to(new_user_profile_path(user))
      end
    end

    context 'positive responses for index page' do
      let(:user) { create(:user, :with_profile) }

      before do
        sign_in user

        api_payload = {
          enrolled_courses: [{ id: 101, title: 'API Enrolled Course', creator: 'alice', deleted_at: nil,
                               tier: 'free' }],
          other_courses: [{ id: 102, title: 'API Other Course', creator: 'bob', deleted_at: nil, tier: 'pro' }]
        }
        expect_any_instance_of(CoursesController).to receive(:fetch_courses_payload).once.and_return(
          api_payload.deep_stringify_keys
        )
        get courses_path
      end

      it 'shows the courses index for authenticated users with profiles' do
        expect(response).to have_http_status(:ok)
      end

      it 'renders courses returned by the API response payload', :aggregate_failures do
        expect(response.body).to include('API Enrolled Course')
        expect(response.body).to include('API Other Course')
      end
    end

    it 'falls back to direct db query when API call raises an error' do
      user = create(:user, :with_profile)
      enrolled_course = create(:course, title: 'DB Enrolled Course')
      create(:course, title: 'DB Other Course')
      enrolled_course.authors << create(:user, :with_profile)
      create(:enrollment, user: user, course: enrolled_course)

      sign_in user

      expect_any_instance_of(CoursesController).to receive(:fetch_courses_payload).once.and_raise(StandardError,
                                                                                                  'API unavailable')

      get courses_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('DB Enrolled Course')
      expect(response.body).to include('DB Other Course')
    end
  end

  describe 'POST /courses' do
    let(:user) { create(:user, :with_profile) }
    let(:params) do
      {
        course: {
          title: 'Web Course Title',
          description: 'A long enough description for the web request spec.',
          tier: 'free'
        }
      }
    end

    before do
      sign_in user
    end

    it 'creates a course and redirects to the edit page' do
      expect do
        post courses_path, params: params
      end.to change(Course, :count).by(1)

      course = Course.order(:created_at).last
      expect(response).to redirect_to(edit_course_path(course))
      expect(course.creator).to eq(user.profile.username)
      expect(course.authors).to include(user)
    end

    it 'returns unprocessable entity for invalid params' do
      post courses_path,
           params: { course: { title: 'bad', description: 'short', tier: 'free' } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /courses/:id' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: user.profile.username) }

    before do
      sign_in user
      course.authors << user
    end

    it 'updates the course and redirects to courses index' do
      patch course_path(course), params: { course: { title: 'Renamed Web Course' } }

      expect(response).to redirect_to(courses_path(course))
      expect(course.reload.title).to eq('Renamed Web Course')
    end

    it 'returns unprocessable entity for invalid updates' do
      patch course_path(course), params: { course: { title: 'bad' } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /courses/:id' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: user.profile.username) }

    before do
      sign_in user
      course.authors << user
    end

    it 'soft deletes the course and redirects to courses index' do
      delete course_path(course)

      expect(response).to redirect_to(courses_path)
      expect(course.reload.deleted_at).to be_present
    end
  end

  describe 'GET /workspace' do
    it 'shows the workspace for authenticated users with profiles' do
      user = create(:user, :with_profile)
      sign_in user

      get workspace_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /courses/:id/update_authors' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }

    before do
      sign_in author
      course.authors << author
    end

    it 'updates authors and redirects with a notice when usernames are found' do
      candidate = create(:user, :with_profile)

      patch update_authors_course_path(course), params: { authors_csv: candidate.profile.username }

      expect(response).to redirect_to(edit_course_path(course))
      expect(flash[:authors_notice]).to eq('Authors updated.')
      expect(course.reload.authors).to include(candidate)
    end

    it 'redirects with an alert when requested usernames are missing' do
      patch update_authors_course_path(course), params: { authors_csv: 'missing_user' }

      expect(response).to redirect_to(edit_course_path(course))
      expect(flash[:authors_alert]).to include('Users not found: missing_user')
    end
  end
end
