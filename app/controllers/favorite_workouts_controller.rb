class FavoriteWorkoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workout

  def create
    current_user.favorites.find_or_create_by!(favorited: @workout)
    redirect_to @workout, notice: "Workout agregado a favoritos", status: :see_other
  end

  def destroy
    current_user.favorites.where(favorited: @workout).destroy_all
    redirect_to @workout, notice: "Workout removido de favoritos", status: :see_other
  end

  private

  def set_workout
    @workout = Workout.find(params[:workout_id] || params[:id])
  end
end
