class ProfilesController < ApplicationController
  before_action :set_user
  before_action :set_profile

  def show
  end

  def new
    redirect_to edit_user_profile_path(@user) if @profile.persisted?
  end

  def create
    @profile.assign_attributes(profile_params)

    if @profile.save
      redirect_to user_profile_path(@user)
    else
      ensure_subscription
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to new_user_profile_path(@user) unless @profile.persisted?
  end

  def update
    if @profile.update(profile_params)
      redirect_to user_profile_path(@user)
    else
      ensure_subscription
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_profile
    @profile = @user.profile || @user.build_profile
    ensure_subscription
  end

  def ensure_subscription
    @profile.build_subscription unless @profile.subscription.present?
  end

  def profile_params
    params.require(:profile).permit(
      :name,
      :bio,
      :username,
      subscription_attributes: [:id, :plan_name]
    )
  end
end