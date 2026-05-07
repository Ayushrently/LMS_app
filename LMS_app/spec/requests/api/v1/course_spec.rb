require 'rails_helper'

RSpec.describe 'API V1 Courses', type: :request do
  let!(:course_access_scopes) { 'public course_access' }

  def json_response
    JSON.parse(response.body)
  end

  def course_payload(title: 'API Testing Course', description: 'Description long enough for validation.', tier: 'free')
    { title: title, description: description, tier: tier }
  end

  describe 'GET /api/v1/courses' do
    let(:path) { '/api/v1/courses' }
    let(:user) { create(:user, :with_profile) }

    subject(:perform_request) { get path, headers: auth_headers_for(user) }

    it 'returns unauthorized without a bearer token' do
      get path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns enrolled and other active courses for the current user' do
      enrolled_course = create(:course, title: 'Ruby Basics', creator: 'author_one')
      other_course = create(:course, title: 'Rails Patterns', creator: 'author_two')
      authored_course = create(:course, title: 'Private Draft', creator: user.profile.username)
      authored_course.authors << user
      create(:enrollment, user: user, course: enrolled_course)

      perform_request

      expect(response).to have_http_status(:ok)
      enrolled_ids = json_response['enrolled_courses'].map { |course| course['id'] }
      other_ids = json_response['other_courses'].map { |course| course['id'] }

      expect(enrolled_ids).to include(enrolled_course.id)
      expect(other_ids).to include(other_course.id)
      expect(other_ids).not_to include(enrolled_course.id, authored_course.id)
    end

    it 'does not return courses that are soft-deleted' do
      active_course = create(:course, title: 'Active Course', creator: 'author_one')
      deleted_course = create(:course, title: 'Deleted Course', creator: 'author_two', deleted_at: 1.day.ago)

      perform_request

      expect(response).to have_http_status(:ok)
      course_ids = json_response['enrolled_courses'].pluck('id') +
                   json_response['other_courses'].pluck('id')

      expect(course_ids).to include(active_course.id)
      expect(course_ids).not_to include(deleted_course.id)
    end
  end

  describe 'GET /api/v1/courses/:id' do
    let(:user) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: 'author_one') }
    let(:course_id) { course.id }

    subject(:perform_request) { get "/api/v1/courses/#{course_id}", headers: auth_headers_for(user) }

    it 'returns unauthorized without a bearer token' do
      get "/api/v1/courses/#{course.id}"

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns the course details for an enrolled user' do
      create(:enrollment, user: user, course: course)

      perform_request

      expect(response).to have_http_status(:ok)
      expected_attributes = course.attributes.slice(*json_response['course'].keys)
      expect(json_response['course']).to eq(expected_attributes)
      expect(json_response['enrollment_status']).to eq('enrolled')
    end

    it 'returns not_enrolled status for a non-enrolled user' do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(json_response['enrollment_status']).to eq('not_enrolled')
    end

    it 'returns not found for a missing course id' do
      get '/api/v1/courses/999_999', headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
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

    it 'should allow a student to create a course and promote them to author', :aggrigate_failures do
      expect { perform_request }.to change(Course, :count).by(1)

      expect(response).to have_http_status(:created)

      created_course = Course.order(:created_at).last
      expect(created_course.creator).to eq(user.profile.username)
      expect(created_course.authors).to include(user)
    end

    it 'returns unprocessable entity for invalid params' do
      post path,
           params: { course: course_payload(title: 'abc', description: 'short', tier: 'free') },
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to be_present
    end

    it 'returns internal server error when course key is missing' do
      post path,
           params: { title: 'No wrapper key' },
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:internal_server_error)
      expect(json_response['error']).to be_present
    end
  end

  describe 'PATCH /api/v1/courses/:id' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }
    let(:course_id) { course.id }
    let(:request_user) { author }
    let(:request_scopes) { course_access_scopes }
    let(:params) { { course: { title: 'Renamed Course' } } }

    subject(:perform_request) do
      patch "/api/v1/courses/#{course_id}",
            params: params,
            headers: auth_headers_for(request_user, scopes: request_scopes)
    end

    before do
      course.authors << author
    end

    it 'returns unauthorized without a bearer token' do
      patch "/api/v1/courses/#{course.id}", params: { course: { title: 'Renamed Course' } }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'forbids updates when the token is missing the course_access scope' do
      patch "/api/v1/courses/#{course.id}",
            params: params,
            headers: auth_headers_for(author)

      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids updates by non-authors even with course_access scope' do
      non_author = create(:user, :with_profile)

      patch "/api/v1/courses/#{course.id}", params: params,
                                            headers: auth_headers_for(non_author, scopes: course_access_scopes)

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('You must be an author to perform this action')
    end

    it 'returns not found for missing course id' do
      patch '/api/v1/courses/999_999',
            params: params,
            headers: auth_headers_for(author, scopes: course_access_scopes)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'updates the course for an author with the course_access scope' do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(course.reload.title).to eq('Renamed Course')
    end

    it 'returns unprocessable entity for invalid updates' do
      patch "/api/v1/courses/#{course.id}",
            params: { course: { title: 'abc' } },
            headers: auth_headers_for(author, scopes: course_access_scopes)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to be_present
    end
  end

  describe 'PATCH /api/v1/courses/:id/add_authors' do
    let(:author) { create(:user, :with_profile) }
    let(:candidate) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }
    let(:course_id) { course.id }
    let(:request_user) { author }
    let(:request_scopes) { course_access_scopes }
    let(:authors_csv) { [candidate.profile.username] }
    let(:params) { { authors_csv: authors_csv } }

    subject(:perform_request) do
      patch "/api/v1/courses/#{course_id}/add_authors",
            params: params,
            headers: auth_headers_for(request_user, scopes: request_scopes)
    end

    before do
      course.authors << author
    end

    it 'returns unauthorized without a bearer token' do
      patch "/api/v1/courses/#{course.id}/add_authors", params: { authors_csv: ['anyone'] }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects unknown usernames' do
      patch "/api/v1/courses/#{course.id}/add_authors",
            params: { authors_csv: ['missing_user'] },
            headers: auth_headers_for(author, scopes: course_access_scopes)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['missing']).to eq(['missing_user'])
    end

    it 'forbids add_authors when token is missing course_access scope' do
      patch "/api/v1/courses/#{course.id}/add_authors",
            params: { authors_csv: [candidate.profile.username] },
            headers: auth_headers_for(author)

      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids add_authors by non-authors even with scope' do
      non_author = create(:user, :with_profile)

      patch "/api/v1/courses/#{course.id}/add_authors",
            params: { authors_csv: [candidate.profile.username] },
            headers: auth_headers_for(non_author, scopes: course_access_scopes)

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('You must be an author to perform this action')
    end

    it 'returns unprocessable entity when no usernames are provided' do
      patch "/api/v1/courses/#{course.id}/add_authors", params: { authors_csv: ['   '] },
                                                        headers: auth_headers_for(author, scopes: course_access_scopes)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to eq('No valid author usernames provided')
    end

    it 'returns not found for missing course id' do
      patch '/api/v1/courses/999_999/add_authors',
            params: { authors_csv: [candidate.profile.username] },
            headers: auth_headers_for(author, scopes: course_access_scopes)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'adds new authors successfully' do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq('Authors added successfully')
      expect(json_response['added_usernames']).to include(candidate.profile.username)
      expect(course.reload.authors).to include(candidate)
    end

    it 'returns success message when all usernames are already authors' do
      course.authors << candidate

      perform_request

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq('All provided users are already authors')
    end

    it 'reports skipped existing usernames when request includes mixed existing and new authors' do
      existing_author = create(:user, :with_profile)
      new_author = create(:user, :with_profile)
      course.authors << existing_author

      patch "/api/v1/courses/#{course.id}/add_authors",
            params: { authors_csv: [existing_author.profile.username, new_author.profile.username] },
            headers: auth_headers_for(author, scopes: course_access_scopes)

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq('Authors added successfully')
      expect(json_response['added_usernames']).to include(new_author.profile.username)
      expect(json_response['skipped_existing_usernames']).to include(existing_author.profile.username)
      expect(course.reload.authors).to include(new_author)
    end
  end

  describe 'PATCH /api/v1/courses/:id/remove_authors' do
    let(:author) { create(:user, :with_profile) }
    let(:removable) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }
    let(:course_id) { course.id }
    let(:request_user) { author }
    let(:request_scopes) { course_access_scopes }
    let(:authors_csv) { [removable.profile.username] }

    subject(:perform_request) do
      patch "/api/v1/courses/#{course_id}/remove_authors",
            params: { authors_csv: authors_csv },
            headers: auth_headers_for(request_user, scopes: request_scopes)
    end

    before do
      course.authors << author
      course.authors << removable
    end

    it 'returns unauthorized without a bearer token' do
      patch "/api/v1/courses/#{course.id}/remove_authors", params: { authors_csv: ['anyone'] }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'forbids remove_authors when token is missing course_access scope' do
      patch "/api/v1/courses/#{course.id}/remove_authors",
            params: { authors_csv: [removable.profile.username] },
            headers: auth_headers_for(author)

      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids remove_authors by non-authors even with scope' do
      non_author = create(:user, :with_profile)

      patch "/api/v1/courses/#{course.id}/remove_authors",
            params: { authors_csv: [removable.profile.username] },
            headers: auth_headers_for(non_author, scopes: course_access_scopes)

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('You must be an author to perform this action')
    end

    it 'returns unprocessable entity when trying to remove the creator' do
      patch "/api/v1/courses/#{course.id}/remove_authors",
            params: { authors_csv: [author.profile.username] },
            headers: auth_headers_for(author, scopes: course_access_scopes)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to eq('Creator cannot be removed from authors')
    end

    it 'returns unprocessable entity for unknown usernames' do
      patch "/api/v1/courses/#{course.id}/remove_authors",
            params: { authors_csv: ['missing_user'] },
            headers: auth_headers_for(author, scopes: course_access_scopes)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to eq('Some users not found')
      expect(json_response['missing']).to eq(['missing_user'])
    end

    it 'returns unprocessable entity when no usernames are provided' do
      patch "/api/v1/courses/#{course.id}/remove_authors",
            params: { authors_csv: ['   '] },
            headers: auth_headers_for(author, scopes: course_access_scopes)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to eq('No valid author usernames provided')
    end

    it 'returns not found for missing course id' do
      patch '/api/v1/courses/999_999/remove_authors',
            params: { authors_csv: ['someone'] },
            headers: auth_headers_for(author, scopes: course_access_scopes)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'removes authors successfully for valid requests' do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq('Authors removed successfully')
      expect(course.reload.authors).not_to include(removable)
    end
  end

  describe 'GET /api/v1/courses/:id/authors' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }

    before do
      course.authors << author
    end

    it 'returns unauthorized without a bearer token' do
      get "/api/v1/courses/#{course.id}/authors"

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns not found for missing course id' do
      user = create(:user, :with_profile)

      get '/api/v1/courses/999_999/authors', headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'returns authors list for a valid course' do
      get "/api/v1/courses/#{course.id}/authors", headers: auth_headers_for(author)

      expect(response).to have_http_status(:ok)
      expect(json_response['authors'].first['id']).to eq(author.id)
    end
  end

  describe 'DELETE /api/v1/courses/:id' do
    let(:author) { create(:user, :with_profile) }
    let(:course) { create(:course, creator: author.profile.username) }
    let(:course_id) { course.id }
    let(:request_user) { author }
    let(:request_scopes) { course_access_scopes }

    subject(:perform_request) do
      delete "/api/v1/courses/#{course_id}", headers: auth_headers_for(request_user, scopes: request_scopes)
    end

    before do
      course.authors << author
    end

    it 'returns unauthorized without a bearer token' do
      delete "/api/v1/courses/#{course.id}"

      expect(response).to have_http_status(:unauthorized)
    end

    it 'forbids destroy when token is missing course_access scope' do
      delete "/api/v1/courses/#{course.id}", headers: auth_headers_for(author)

      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids destroy by non-authors even with scope' do
      non_author = create(:user, :with_profile)

      delete "/api/v1/courses/#{course.id}", headers: auth_headers_for(non_author, scopes: course_access_scopes)

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('You must be an author to perform this action')
    end

    it 'returns not found for missing course id' do
      user = create(:user, :with_profile)

      delete '/api/v1/courses/999_999', headers: auth_headers_for(user, scopes: course_access_scopes)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('Course not found')
    end

    it 'returns no content for an author with scope' do
      perform_request

      expect(response).to have_http_status(:no_content)
      expect(course.reload.deleted_at).to be_present
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
