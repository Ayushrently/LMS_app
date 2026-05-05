module AuthHelpers
  module Web
    def sign_in_web(user = create(:user))
      sign_in user
      user
    end
  end

  module Api
    def auth_headers_for(user, scopes: 'public')
      token = create_access_token_for(user, scopes: scopes)
      {
        'Authorization' => "Bearer #{token.token}",
        'ACCEPT' => 'application/json'
      }
    end

    def create_access_token_for(user, scopes: 'public', expires_in: 2.hours)
      application = Doorkeeper::Application.find_or_create_by!(
        name: 'RSpec Doorkeeper Application',
        redirect_uri: 'urn:ietf:wg:oauth:2.0:oob'
      ) do |app|
        app.scopes = 'public'
      end

      Doorkeeper::AccessToken.create!(
        application_id: application.id,
        resource_owner_id: user.id,
        scopes: scopes,
        expires_in: expires_in.to_i
      )
    end

    # Use this helper when you specifically want to test password grant flow.
    def password_grant_token_for(user, password: 'password', scopes: 'public')
      post '/oauth/token', params: {
        grant_type: 'password',
        email: user.email,
        password: password,
        scope: scopes
      }

      JSON.parse(response.body).fetch('access_token')
    end
  end
end
