class UsersController < ApplicationController
  before_action :set_user, only: [:show]

  def new
    @user = User.new(role: :student)
  end

  def create
    normalized_email = user_params[:email].to_s.downcase.strip
    @user = User.find_or_initialize_by(email: normalized_email)
    @user.role = user_params[:role]

    if @user.save
      set_current_user(@user)
      redirect_to next_profile_step_for(@user)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    if @user.profile.present?
      redirect_to user_profile_path(@user)
    else
      redirect_to new_user_profile_path(@user)
    end
  end

  def logout
    clear_current_user
    redirect_to new_user_path
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :role)
  end

  def next_profile_step_for(user)
    user.profile.present? ? courses_path : new_user_profile_path(user)
  end
end