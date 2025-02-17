class FavoriteWorkoutsController < ApplicationController
  before_action :set_workout

    def index
        @workouts = current_user.favorite_workouts
    end
  
  def create
    if Favorite.create(favorited: @workout, user: current_user)
      redirect_to @workout, notice: 'Workout agregado a favoritos'
    else
      redirect_to @workout, alert: 'Oh no, algo salió mal'
    end
  end
  
  def destroy
    Favorite.where(favorited_id: @workout.id, user_id: current_user.id).first.destroy
    redirect_to @workout, notice: 'Workout removido de favoritos'
  end
  
  private
  
  def set_workout
    @workout = Workout.find(params[:workout_id] || params[:id])
  end

end