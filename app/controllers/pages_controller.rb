class PagesController < ApplicationController
  def index
    @workouts = Workout.where(day: Date.today.all_day)
  end

  def acerca
  end

  def preguntasfrecuentes
  end

  def terminos
  end
end
