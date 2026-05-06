class TokenController < ApplicationController
  before_action :authenticate_user!

  def show
    app = Doorkeeper::AccessToken.find_or_create_for(
      application: nil,
      resource_owner: current_user,
      scopes: 'public',
      expires_in: 7200,
      use_refresh_token: true
    )

    render json: { access_token: app.token }
  end
end
