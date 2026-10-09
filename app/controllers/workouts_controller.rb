# Catálogo público (solo lectura). Crear, editar y borrar workouts vive en
# /admin (Admin::WorkoutsController).
class WorkoutsController < ApplicationController
  before_action :authenticate_user!, only: :favorites
  before_action :set_workout, only: :show
  before_action :initialize_search, only: %i[all index]

  # GET /workouts (y /workouts.json para el calendario)
  def index
    @workouts = Workout.all
    @workoutsFeatured = Workout.where("day < ?", Date.current).order(day: :desc).limit(4)
    @workoutLowerBody = Workout.limit(10).where(category: "Lower Body")
    @workoutAbsCore = Workout.limit(10).where(category: "ABS and Core")
    @workoutFullBody = Workout.limit(10).where(category: "Full Body")
    @workoutGlutesHips = Workout.limit(10).where(category: "Glutes and Hips")
    @workoutUpperBody = Workout.limit(10).where(category: "Upper Body")
    @workout1530 = Workout.where(duration: [ "15min", "30min" ])
    @workoutStrength = Workout.limit(10).where(strength: true)
  end

  def upperbody
    @workoutUpperBody = Workout.all.order("created_at DESC").where(category: "Upper Body")
  end

  def lowerbody
    @workoutLowerBody = Workout.all.order("created_at DESC").where(category: "Lower Body")
  end

  def abscore
    @workoutAbsCore = Workout.all.order("created_at DESC").where(category: "ABS and Core")
  end

  def fullbody
    @workoutFullBody = Workout.all.order("created_at DESC").where(category: "Full Body")
  end

  def gluteships
    @workoutGlutesHips = Workout.all.order("created_at DESC").where(category: "Glutes and Hips")
  end

  def short_1530
    @workout1530 = Workout.where(duration: [ "15min", "30min" ])
  end

  def strength
    @workoutStrength = Workout.limit(10).where(strength: true)
  end

  def favorites
    @workouts = current_user.favorite_workouts
  end

  def all
    handle_filters
  end

  def show
    @comments = @workout.comments.roots.includes(:user, replies: :user).order(:created_at)
  end

  private

    def initialize_search
      params[:intensidad] = nil if params[:intensidad] == ""
      session[:intensidad] = params[:intensidad]
      params[:categoria] = nil if params[:categoria] == ""
      session[:categoria] = params[:categoria]
      params[:duracion] = nil if params[:duracion] == ""
      session[:duracion] = params[:duracion]
    end

    def handle_filters
      filters = {}
      filters[:intensity] = session[:intensidad] if session[:intensidad].present?
      filters[:category] = session[:categoria] if session[:categoria].present?
      filters[:duration] = session[:duracion] if session[:duracion].present?

      @workouts = filters.empty? ? Workout.last(9) : Workout.where(filters)
    end

    def set_workout
      @workout = Workout.find(params[:id])
    end
end
