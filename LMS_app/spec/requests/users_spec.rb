require 'rails_helper'

RSpec.describe 'Users', type: :request do
  describe 'GET /users/:id' do
    it 'redirects to sign in when unauthenticated' do
      user = create(:user, :with_profile)

      get user_path(user)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to the profile page when the user has a profile' do
      user = create(:user, :with_profile)
      sign_in user

      get user_path(user)

      expect(response).to redirect_to(user_profile_path(user))
    end

    it 'redirects to the new profile page when the user has no profile' do
      user = create(:user)
      sign_in user

      get user_path(user)

      expect(response).to redirect_to(new_user_profile_path(user))
    end
  end
end