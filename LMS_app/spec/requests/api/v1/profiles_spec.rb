# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Profiles', type: :request do
  let(:profile_access_scopes) { 'public profile_access' }

  def json_response
    response.parsed_body
  end

  describe 'GET /api/v1/users/:user_id/profile' do
    let(:user) { create(:user, :with_profile) }
    let(:path) { "/api/v1/users/#{user.id}/profile" }

    subject(:perform_request) { get path, headers: auth_headers_for(user) }

    it 'returns unauthorized without a bearer token' do
      get path

      expect(response).to have_http_status(:unauthorized)
    end

    context 'when user does not exist' do
      before do
        get '/api/v1/users/999_999/profile', headers: auth_headers_for(user)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('User not found')
      end
    end

    context 'when user has a profile' do
      before { perform_request }

      it 'returns profile payload', :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(json_response['id']).to eq(user.profile.id)
        expect(json_response['username']).to eq(user.profile.username)
      end
    end

    context 'when user has no profile' do
      let(:user_without_profile) { create(:user) }

      before do
        get "/api/v1/users/#{user_without_profile.id}/profile", headers: auth_headers_for(user_without_profile)
      end

      it 'returns ok with null payload', :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(json_response).to be_nil
      end
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

    context 'when user does not exist' do
      before do
        post '/api/v1/users/999_999/profile',
             params: { profile: profile_params },
             headers: auth_headers_for(user)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('User not found')
      end
    end

    context 'when user has no profile' do
      it 'creates profile and returns created payload', :aggregate_failures do
        expect { perform_request }.to change(Profile, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json_response['username']).to eq('ayush_user')
      end
    end

    context 'when user already has a profile' do
      let(:user_with_profile) { create(:user, :with_profile) }

      before do
        post "/api/v1/users/#{user_with_profile.id}/profile",
             params: { profile: profile_params },
             headers: auth_headers_for(user_with_profile)
      end

      it 'returns unprocessable entity and profile exists error', :aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Profile already exists for this user')
      end
    end

    context 'when profile params are invalid' do
      before do
        post path,
             params: { profile: { name: 'ab', username: 'x', bio: 'Profile bio' } },
             headers: auth_headers_for(user)
      end

      it 'returns unprocessable entity with validation errors', :aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to be_present
      end
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

    context 'when request is valid' do
      before { perform_request }

      it 'updates profile and returns ok', :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(user.profile.reload.bio).to eq('Updated bio')
      end
    end

    context 'when user does not exist' do
      before do
        patch '/api/v1/users/999_999/profile',
              params: params,
              headers: auth_headers_for(user, scopes: profile_access_scopes)
      end

      it 'returns not found status and message', :aggregate_failures do
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('User not found')
      end
    end

    context 'when requester updates another users profile' do
      let(:other_user) { create(:user, :with_profile) }

      before do
        patch "/api/v1/users/#{other_user.id}/profile",
              params: params,
              headers: auth_headers_for(user, scopes: profile_access_scopes)
      end

      it 'returns forbidden with ownership error', :aggregate_failures do
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq("You cannot change other's profile")
      end
    end

    context 'when update params are invalid' do
      before do
        patch path,
              params: { profile: { username: 'x' } },
              headers: auth_headers_for(user, scopes: profile_access_scopes)
      end

      it 'returns unprocessable entity with validation errors', :aggregate_failures do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to be_present
      end
    end
  end
end
