class Api::V1::ProfilesController < Api::V1::BaseController
  before_action :set_user
  before_action -> { doorkeeper_authorize! :profile_access }, only: [:update]

  def show
    render json: @user.profile, status: :ok
  end

  def create
    if @user.profile.present?
      render json: { error: "Profile already exists for this user" }, status: :unprocessable_entity
      return
    end
    @profile = @user.build_profile(profile_params)
    if @profile.save
      render json: @profile, status: :created
    else
      render json: { errors: @profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @profile = @user.profile
    if @profile.username.present? && @profile.username != current_user.profile.username
      render json: { error: "You cannot change other's profile" }, status: :forbidden
      return
    end
    if @profile.update(profile_params)
      render json: @profile, status: :ok
    else
      render json: { errors: @profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find_by(id: params[:user_id])
    render json: { error: "User not found" }, status: :not_found unless @user
  end

  def profile_params
    params.require(:profile).permit(:bio, :name, :username, subscription_attributes: [:plan_name])
  end
end