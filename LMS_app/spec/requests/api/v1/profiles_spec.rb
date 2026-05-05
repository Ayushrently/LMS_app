require 'rails_helper'

RSpec.describe 'API V1 Profiles', type: :request do
  let(:profile_access_scopes) { 'public profile_access' }

  def json_response
    JSON.parse(response.body)
  end

  describe 'GET /api/v1/users/:user_id/profile' do
    let(:user) { create(:user, :with_profile) }
    let(:path) { "/api/v1/users/#{user.id}/profile" }

    subject(:perform_request) { get path, headers: auth_headers_for(user) }

    it 'returns unauthorized without a bearer token' do
      get path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns not found when user does not exist' do
      get '/api/v1/users/999_999/profile', headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('User not found')
    end

    it 'returns the user profile for an authenticated request' do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(json_response['id']).to eq(user.profile.id)
      expect(json_response['username']).to eq(user.profile.username)
    end

    it 'returns null when the user has no profile yet' do
      user_without_profile = create(:user)

      get "/api/v1/users/#{user_without_profile.id}/profile", headers: auth_headers_for(user_without_profile)

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_nil
    end
  end

  describe 'POST /api/v1/users/:user_id/profile' do
    let(:user) { create(:user) }
    let(:path) { "/api/v1/users/#{user.id}/profile" }
    let(:profile_params) do
      build(:profile, name: 'Ayush', username: 'ayush_user', bio: 'Profile bio')
        .attributes.slice('name', 'username', 'bio').symbolize_keys
    end

    subject(:perform_request) { post path, params: { profile: profile_params }, headers: auth_headers_for(user) }

    it 'returns unauthorized without a bearer token' do
      post path, params: { profile: profile_params }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns not found when user does not exist' do
      post '/api/v1/users/999_999/profile',
           params: { profile: profile_params },
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('User not found')
    end

    it 'creates a profile for a user without one' do
      expect { perform_request }.to change(Profile, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['username']).to eq('ayush_user')
    end

    it 'returns unprocessable entity when profile already exists' do
      user_with_profile = create(:user, :with_profile)

      post "/api/v1/users/#{user_with_profile.id}/profile",
           params: { profile: profile_params },
           headers: auth_headers_for(user_with_profile)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['error']).to eq('Profile already exists for this user')
    end

    it 'returns unprocessable entity for invalid profile params' do
      post path,
           params: { profile: { name: 'ab', username: 'x', bio: 'Profile bio' } },
           headers: auth_headers_for(user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to be_present
    end
  end

  describe 'PATCH /api/v1/users/:user_id/profile' do
    let(:user) { create(:user, :with_profile) }
    let(:path) { "/api/v1/users/#{user.id}/profile" }
    let(:request_user) { user }
    let(:params) { { profile: { bio: 'Updated bio' } } }

    subject(:perform_request) do
      patch path,
            params: params,
            headers: auth_headers_for(request_user, scopes: profile_access_scopes)
    end

    it 'returns unauthorized without a bearer token' do
      patch path, params: params

      expect(response).to have_http_status(:unauthorized)
    end

    it 'forbids profile updates without the profile_access scope' do
      patch path,
            params: params,
            headers: auth_headers_for(user)

      expect(response).to have_http_status(:forbidden)
    end

    it 'updates the profile with the profile_access scope' do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(user.profile.reload.bio).to eq('Updated bio')
    end

    it 'returns not found when user does not exist' do
      patch '/api/v1/users/999_999/profile',
            params: params,
            headers: auth_headers_for(user, scopes: profile_access_scopes)

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq('User not found')
    end

    it 'forbids updates to another users profile' do
      other_user = create(:user, :with_profile)

      patch "/api/v1/users/#{other_user.id}/profile",
            params: params,
            headers: auth_headers_for(user, scopes: profile_access_scopes)

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq("You cannot change other's profile")
    end

    it 'returns unprocessable entity for invalid update params' do
      patch path,
            params: { profile: { username: 'x' } },
            headers: auth_headers_for(user, scopes: profile_access_scopes)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to be_present
    end
  end
end
