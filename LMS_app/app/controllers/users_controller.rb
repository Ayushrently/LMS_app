class UsersController < ApplicationController
  before_action :set_user, only: [:show]

  def show
    if @user.profile.present?
      redirect_to user_profile_path(@user)
    else
      redirect_to new_user_profile_path(@user)
    end
  end

  private

  def set_user
    @user = User.find_by(id:params[:id])
  end

end