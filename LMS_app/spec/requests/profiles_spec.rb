# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profiles', type: :request do
  describe 'GET /users/:user_id/profile' do
    it 'redirects to sign in when unauthenticated' do
      user = create(:user, :with_profile)

      get user_profile_path(user)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'shows the profile for an authenticated user' do
      user = create(:user, :with_profile)
      sign_in user

      get user_profile_path(user)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /users/:user_id/profile/new' do
    it 'redirects to edit when the profile already exists' do
      user = create(:user, :with_profile)
      sign_in user

      get new_user_profile_path(user)

      expect(response).to redirect_to(edit_user_profile_path(user))
    end
  end

  describe 'GET /users/:user_id/profile/edit' do
    it 'redirects to new when the profile does not exist yet' do
      user = create(:user)
      sign_in user

      get edit_user_profile_path(user)

      expect(response).to redirect_to(new_user_profile_path(user))
    end
  end

  describe 'POST /users/:user_id/profile' do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it 'creates a profile and redirects to the profile page' do
      expect do
        post user_profile_path(user), params: {
          profile: {
            name: 'Web User',
            username: 'web_user',
            bio: 'Profile bio from request spec.'
          }
        }
      end.to change(Profile, :count).by(1)

      expect(response).to redirect_to(user_profile_path(user))
    end

    it 'returns unprocessable entity for invalid params' do
      post user_profile_path(user), params: { profile: { name: 'ab', username: 'xy' } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /users/:user_id/profile' do
    let(:user) { create(:user, :with_profile) }

    before do
      sign_in user
    end

    it 'updates the profile and redirects to the show page' do
      patch user_profile_path(user), params: { profile: { bio: 'Updated web profile bio.' } }

      expect(response).to redirect_to(user_profile_path(user))
      expect(user.profile.reload.bio).to eq('Updated web profile bio.')
    end

    it 'returns unprocessable entity for invalid updates' do
      patch user_profile_path(user), params: { profile: { username: 'xy' } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
