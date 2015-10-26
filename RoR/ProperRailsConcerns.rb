###########################################################################################
# Shows proper use of concerns to both keep controllers clean and make common code reusable
###########################################################################################
#app/controllers/user_controller.rb
class UserController < ApplicationController
  include Userable

  helper_method :user, :users

  def create
    user.save
    redirect_to new_user_path
  end

  def update
    user.update_attributes user_params
    redirect_to edit_user_path(user)
  end
end

#app/controllers/concerns/userable.rb
module Userable
  extend ActiveSupport::Concern

  private

  def users
    @users ||= User.all
  end

  def user
    @user ||= load_user
  end

  def load_user
    blank_user || found_user || created_user || nil
  end

  def blank_user
    %w(new).include?(params[:action]) && User.new
  end

  def found_user
    %w(show edit update).include?(params[:action]) && User.find(params[:id])
  end

  def created_user
    %w(create).include?(params[:action]) && User.new(user_params)
  end

  def user_params
    params.require(:user).permit(:name, :age)
  end
end