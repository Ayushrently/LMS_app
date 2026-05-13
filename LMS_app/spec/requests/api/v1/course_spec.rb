# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Courses', type: :request do
  let(:course_access_scopes) { 'public course_access' }

  def json_response
    response.parsed_body
  end

  def course_payload(title: 'API Testing Course', description: 'Description long enough for validation.', tier: 'free')
    { title: title, description: description, tier: tier }
  end

  describe 'GET /api/v1/courses' do
    let(:user) { create(:user, :with_profile) }
    let(:path) { '/api/v1/courses' }

    subject(:perform_request) { get path, headers: auth_headers_for(user) }

    it 'returns unauthorized without a bearer token' do
      get path

      expect(response).to have_http_status(:unauthorized)
    end

    context 'when the request is valid' do
      let(:enrolled_course) { create(:course, title: 'Ruby Basics', creator: 'author_one') }
      let!(:other_course) { create(:course, title: 'Rails Patterns', creator: 'author_two') }
      let!(:soft_deleted_course) do
        create(:course, title: 'Rails Patterns1', creator: 'author_two', deleted_at: Time.current)
      end
      let(:authored_course) { create(:course, title: 'Private Draft', creator: user.profile.username) }

      before do
        authored_course.authors << user
        create(:enrollment, user: user, course: enrolled_course)

        perform_request
      end

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns enrolled courses for the current user' do
        expect(json_response['enrolled_courses']).to include(a_hash_including('id' => enrolled_course.id))
      end

      it 'does not return authored course for current user' do
        courses = json_response['enrolled_courses'] + json_response['other_courses']

        expect(courses).not_to include(a_hash_including('id' => authored_course.id))
      end

      it 'does not return soft deleted courses in other_courses' do
        expect(json_response['other_courses']).not_to include(a_hash_including('id' => soft_deleted_course.id))
      end

      it 'returns active courses in other_courses' do
        expect(json_response['other_courses']).to include(a_hash_including('id' => other_course.id))
      end

      it 'returns soft deleted courses when the user is enrolled in them' do
        enrolled_course.update!(deleted_at: Time.current)

        perform_request

        expect(json_response['enrolled_courses']).to include(a_hash_including('id' => enrolled_course.id))
      end
    end
  end

  describe 'GET /api/v1/courses/:id' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: 'author_one') }
    let(:course_id) { course.id }
    let(:path) { "/api/v1/courses/#{course_id}" }

    subject(:perform_request) { get path, headers: auth_headers_for(user) }

    context 'when request is missing bearer token' do
      before { get path }

      it 'returns unauthorized without a bearer token' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when course exists' do
      context 'when user is not enrolled' do
        let(:expected_attributes) { course.attributes.slice(*json_response['course'].keys) }

        before { perform_request }

        it 'returns ok' do
          expect(response).to have_http_status(:ok)
        end

        it 'returns course details' do
          expect(json_response['course']).to eq(expected_attributes)
        end

        it 'returns not_enrolled status' do
          expect(json_response['enrollment_status']).to eq('not_enrolled')
        end
      end

      context 'when user is enrolled' do
        before do
          create(:enrollment, user: user, course: course)
          perform_request
        end

        it 'returns enrolled status' do
          expect(json_response['enrollment_status']).to eq('enrolled')
        end
      end
    end

    context 'when course does not exist' do
      let(:path) { '/api/v1/courses/99999_9' }

      before { perform_request }

      it 'returns not found for a missing course id' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns course not found error' do
        expect(json_response['error']).to eq('Course not found')
      end
    end
  end

  describe 'POST /api/v1/courses' do
    let(:path) { '/api/v1/courses' }
    let(:user) { create(:user, :with_profile) }
    let(:course_params) do
      build(:course,
            title: 'API Testing Course',
            description: 'Description long enough for validation.',
            tier: 'free').attributes.slice('title', 'description', 'tier').symbolize_keys
    end
    let(:params) { { course: course_params } }

    subject(:perform_request) { post path, params: params, headers: auth_headers_for(user) }

    it 'returns unauthorized without a bearer token' do
      post path, params: params

      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates a course' do
      expect { perform_request }.to change(Course, :count).by(1)
    end

    context 'when creation succeeds' do
      before { perform_request }

      let(:created_course) { Course.order(:created_at).last }

      it 'returns created status' do
        expect(response).to have_http_status(:created)
      end

      it 'sets creator to request user username' do
        expect(created_course.creator).to eq(user.profile.username)
      end

      it 'adds request user to course authors' do
        expect(created_course.authors).to include(user)
      end
    end

    context 'when params are invalid' do
      before do
        post path,
             params: { course: course_payload(title: 'abc', description: 'short', tier: 'free') },
             headers: auth_headers_for(user)
      end

      it 'returns unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation errors' do
        expect(json_response['errors']).to be_present
      end
    end

    context 'when course key is missing' do
      before do
        post path,
             params: { title: 'No wrapper key' },
             headers: auth_headers_for(user)
      end

      it 'returns internal server error' do
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'returns error payload' do
        expect(json_response['error']).to be_present
      end
    end
  end

  describe 'PATCH /api/v1/courses/:id' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }
    let(:course_id) { course.id }
    let(:path) { "/api/v1/courses/#{course_id}" }
    let(:request_user) { author }
    let(:request_scopes) { course_access_scopes }
    let(:params) { { course: { title: 'Renamed Course' } } }

    subject(:perform_request) do
      patch path,
            params: params,
            headers: auth_headers_for(request_user, scopes: request_scopes)
    end

    before do
      course.authors << author
    end

    it 'returns unauthorized without a bearer token' do
      patch path, params: params

      expect(response).to have_http_status(:unauthorized)
    end

    it 'forbids updates when the token is missing the course_access scope' do
      patch path,
            params: params,
            headers: auth_headers_for(author)

      expect(response).to have_http_status(:forbidden)
    end

    context 'when requester is not an author' do
      let(:non_author) { create(:user, :with_profile) }

      before do
        patch path,
              params: params,
              headers: auth_headers_for(non_author, scopes: course_access_scopes)
      end

      it 'returns forbidden' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns author-only error' do
        expect(json_response['error']).to eq('You must be an author to perform this action')
      end
    end

    context 'when course id is missing' do
      before do
        patch '/api/v1/courses/999_999',
              params: params,
              headers: auth_headers_for(author, scopes: course_access_scopes)
      end

      it 'returns not found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns course not found error' do
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when author updates with valid params' do
      before { perform_request }

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'updates the course title' do
        expect(course.reload.title).to eq('Renamed Course')
      end
    end

    context 'when update params are invalid' do
      before do
        patch path,
              params: { course: { title: 'abc' } },
              headers: auth_headers_for(author, scopes: course_access_scopes)
      end

      it 'returns unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation errors' do
        expect(json_response['errors']).to be_present
      end
    end
  end

  describe 'PATCH /api/v1/courses/:id/add_authors' do
    let(:author) { create(:user, :with_profile) }
    let(:candidate) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }
    let(:course_id) { course.id }
    let(:path) { "/api/v1/courses/#{course_id}/add_authors" }
    let(:request_user) { author }
    let(:request_scopes) { course_access_scopes }
    let(:authors_csv) { [candidate.profile.username] }
    let(:params) { { authors_csv: authors_csv } }

    subject(:perform_request) do
      patch path,
            params: params,
            headers: auth_headers_for(request_user, scopes: request_scopes)
    end

    before do
      course.authors << author
    end

    it 'returns unauthorized without a bearer token' do
      patch path, params: { authors_csv: ['anyone'] }

      expect(response).to have_http_status(:unauthorized)
    end

    context 'when usernames are unknown' do
      before do
        patch path,
              params: { authors_csv: ['missing_user'] },
              headers: auth_headers_for(author, scopes: course_access_scopes)
      end

      it 'returns unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns missing usernames' do
        expect(json_response['missing']).to eq(['missing_user'])
      end
    end

    it 'forbids add_authors when token is missing course_access scope' do
      patch path,
            params: { authors_csv: [candidate.profile.username] },
            headers: auth_headers_for(author)

      expect(response).to have_http_status(:forbidden)
    end

    context 'when requester is not an author' do
      let(:non_author) { create(:user, :with_profile) }

      before do
        patch path,
              params: { authors_csv: [candidate.profile.username] },
              headers: auth_headers_for(non_author, scopes: course_access_scopes)
      end

      it 'returns forbidden' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns author-only error' do
        expect(json_response['error']).to eq('You must be an author to perform this action')
      end
    end

    context 'when no valid usernames are provided' do
      before do
        patch path,
              params: { authors_csv: ['   '] },
              headers: auth_headers_for(author, scopes: course_access_scopes)
      end

      it 'returns unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns empty usernames error' do
        expect(json_response['error']).to eq('No valid author usernames provided')
      end
    end

    context 'when course id is missing' do
      before do
        patch '/api/v1/courses/999_999/add_authors',
              params: { authors_csv: [candidate.profile.username] },
              headers: auth_headers_for(author, scopes: course_access_scopes)
      end

      it 'returns not found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns course not found error' do
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when new authors are added' do
      before { perform_request }

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns success message' do
        expect(json_response['message']).to eq('Authors added successfully')
      end

      it 'returns added usernames' do
        expect(json_response['added_usernames']).to include(candidate.profile.username)
      end

      it 'adds candidate as author' do
        expect(course.reload.authors).to include(candidate)
      end
    end

    context 'when all usernames are already authors' do
      before do
        course.authors << candidate
        perform_request
      end

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns already-authors message' do
        expect(json_response['message']).to eq('All provided users are already authors')
      end
    end

    context 'when request includes mixed existing and new authors' do
      let(:existing_author) { create(:user, :with_profile) }
      let(:new_author) { create(:user, :with_profile) }
      let(:authors_csv) { [existing_author.profile.username, new_author.profile.username] }

      before do
        course.authors << existing_author
        perform_request
      end

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns success message' do
        expect(json_response['message']).to eq('Authors added successfully')
      end

      it 'returns added usernames list with new author' do
        expect(json_response['added_usernames']).to include(new_author.profile.username)
      end

      it 'returns skipped usernames list with existing author' do
        expect(json_response['skipped_existing_usernames']).to include(existing_author.profile.username)
      end

      it 'adds new author to course authors' do
        expect(course.reload.authors).to include(new_author)
      end
    end
  end

  describe 'PATCH /api/v1/courses/:id/remove_authors' do
    let(:author) { create(:user, :with_profile) }
    let(:removable) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }
    let(:course_id) { course.id }
    let(:path) { "/api/v1/courses/#{course_id}/remove_authors" }
    let(:request_user) { author }
    let(:request_scopes) { course_access_scopes }
    let(:authors_csv) { [removable.profile.username] }

    subject(:perform_request) do
      patch path,
            params: { authors_csv: authors_csv },
            headers: auth_headers_for(request_user, scopes: request_scopes)
    end

    before do
      course.authors << author
      course.authors << removable
    end

    it 'returns unauthorized without a bearer token' do
      patch path, params: { authors_csv: ['anyone'] }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'forbids remove_authors when token is missing course_access scope' do
      patch path,
            params: { authors_csv: [removable.profile.username] },
            headers: auth_headers_for(author)

      expect(response).to have_http_status(:forbidden)
    end

    context 'when requester is not an author' do
      let(:non_author) { create(:user, :with_profile) }

      before do
        patch path,
              params: { authors_csv: [removable.profile.username] },
              headers: auth_headers_for(non_author, scopes: course_access_scopes)
      end

      it 'returns forbidden' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns author-only error' do
        expect(json_response['error']).to eq('You must be an author to perform this action')
      end
    end

    context 'when trying to remove creator' do
      before do
        patch path,
              params: { authors_csv: [author.profile.username] },
              headers: auth_headers_for(author, scopes: course_access_scopes)
      end

      it 'returns unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns creator removal error' do
        expect(json_response['error']).to eq('Creator cannot be removed from authors')
      end
    end

    context 'when usernames are unknown' do
      before do
        patch path,
              params: { authors_csv: ['missing_user'] },
              headers: auth_headers_for(author, scopes: course_access_scopes)
      end

      it 'returns unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns users not found error' do
        expect(json_response['error']).to eq('Some users not found')
      end

      it 'returns missing usernames' do
        expect(json_response['missing']).to eq(['missing_user'])
      end
    end

    context 'when no valid usernames are provided' do
      before do
        patch path,
              params: { authors_csv: ['   '] },
              headers: auth_headers_for(author, scopes: course_access_scopes)
      end

      it 'returns unprocessable entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns empty usernames error' do
        expect(json_response['error']).to eq('No valid author usernames provided')
      end
    end

    context 'when course id is missing' do
      before do
        patch '/api/v1/courses/999_999/remove_authors',
              params: { authors_csv: ['someone'] },
              headers: auth_headers_for(author, scopes: course_access_scopes)
      end

      it 'returns not found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns course not found error' do
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when request is valid' do
      before { perform_request }

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns success message' do
        expect(json_response['message']).to eq('Authors removed successfully')
      end

      it 'removes author from course authors' do
        expect(course.reload.authors).not_to include(removable)
      end
    end
  end

  describe 'GET /api/v1/courses/:id/authors' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }
    let(:path) { "/api/v1/courses/#{course.id}/authors" }

    before do
      course.authors << author
    end

    it 'returns unauthorized without a bearer token' do
      get path

      expect(response).to have_http_status(:unauthorized)
    end

    context 'when course id is missing' do
      before do
        user = create(:user, :with_profile)
        get '/api/v1/courses/999_999/authors', headers: auth_headers_for(user)
      end

      it 'returns not found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns course not found error' do
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when request is valid' do
      before { get path, headers: auth_headers_for(author) }

      it 'returns ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns course author in payload' do
        expect(json_response['authors']).to include(a_hash_including('id' => author.id))
      end
    end
  end

  describe 'DELETE /api/v1/courses/:id' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }
    let(:course_id) { course.id }
    let(:path) { "/api/v1/courses/#{course_id}" }
    let(:request_user) { author }
    let(:request_scopes) { course_access_scopes }

    subject(:perform_request) do
      delete path, headers: auth_headers_for(request_user, scopes: request_scopes)
    end

    before do
      course.authors << author
    end

    it 'returns unauthorized without a bearer token' do
      delete path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'forbids destroy when token is missing course_access scope' do
      delete path, headers: auth_headers_for(author)

      expect(response).to have_http_status(:forbidden)
    end

    context 'when requester is not an author' do
      let(:non_author) { create(:user, :with_profile) }

      before do
        delete path, headers: auth_headers_for(non_author, scopes: course_access_scopes)
      end

      it 'returns forbidden' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns author-only error' do
        expect(json_response['error']).to eq('You must be an author to perform this action')
      end
    end

    context 'when course id is missing' do
      before do
        user = create(:user, :with_profile)
        delete '/api/v1/courses/999_999', headers: auth_headers_for(user, scopes: course_access_scopes)
      end

      it 'returns not found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns course not found error' do
        expect(json_response['error']).to eq('Course not found')
      end
    end

    context 'when request is valid' do
      before { perform_request }

      it 'returns no content' do
        expect(response).to have_http_status(:no_content)
      end

      it 'soft deletes the course' do
        expect(course.reload.deleted_at).to be_present
      end
    end

    context 'when delete fails in database' do
      before do
        allow_any_instance_of(Course).to receive(:soft_delete!).and_return(false)
        perform_request
      end

      it 'returns unprocessable entity with error message', :aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to eq('Failed to delete course')
      end
    end
  end

  describe 'GET /api/v1/workspace' do
    let(:path) { '/api/v1/workspace' }
    let(:user) { create(:user, :with_profile) }

    it 'returns unauthorized without a bearer token' do
      get path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns no content for authenticated requests' do
      create(:course, creator: user.profile.username)

      get path, headers: auth_headers_for(user)

      expect(response).to have_http_status(:no_content)
    end
  end
end
