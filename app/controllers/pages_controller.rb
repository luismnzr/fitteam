class PagesController < ApplicationController
  def index
    @workouts = Workout.where(day: Date.current)
  end

  def acerca
  end

  def preguntasfrecuentes
  end

  def terminos
  end
end
