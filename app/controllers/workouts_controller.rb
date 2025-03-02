class WorkoutsController < ApplicationController
  before_action :set_workout, only: %i[ show edit update destroy ]
  before_action :initialize_search, only: %i[ all index ]

  # GET /workouts or /workouts.json
  def index
    @workouts = Workout.all
    @workoutsFeatured = Workout.where("day < ?", Date.today).order(day: :desc).limit(4)
    @workoutsRecent = Workout.last(10)
    @workoutsLast = Workout.order('created_at DESC').where(recent: true)
    @workoutLowerBody = Workout.limit(10).where(category: "Lower Body")
    @workoutAbsCore = Workout.limit(10).where(category: "ABS and Core")
    @workoutFullBody = Workout.limit(10).where(category: "Full Body")
    @workoutGlutesHips = Workout.limit(10).where(category: "Glutes and Hips")
    @workoutUpperBody = Workout.limit(10).where(category: "Upper Body")
  end

  def upperbody
    @workoutUpperBody = Workout.all.order('created_at DESC').where(category: "Upper Body")
  end

  def lowerbody
    @workoutLowerBody = Workout.all.order('created_at DESC').where(category: "Lower Body")
  end

  def abscore
    @workoutAbsCore = Workout.all.order('created_at DESC').where(category: "Abs Core")
  end

  def fullbody
    @workoutFullBody = Workout.all.order('created_at DESC').where(category: "Full Body")
  end

  def gluteships
    @workoutGlutesHips = Workout.all.order('created_at DESC').where(category: "Glutes and Hips")
  end

  def favorites
    @workouts = current_user.favorite_workouts
  end

  def all
    handle_filters
  end

  # GET /workouts/1 or /workouts/1.json
  def show
    @comment = @workout.comments.build
  end

  # GET /workouts/new
  def new
    @workout = Workout.new
  end

  # GET /workouts/1/edit
  def edit
  end

  # POST /workouts or /workouts.json
  def create
    @workout = Workout.new(workout_params)

    respond_to do |format|
      if @workout.save
        format.html { redirect_to @workout, notice: "Workout was successfully created." }
        format.json { render :show, status: :created, location: @workout }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @workout.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /workouts/1 or /workouts/1.json
  def update
    respond_to do |format|
      if @workout.update(workout_params)
        format.html { redirect_to @workout, notice: "Workout was successfully updated." }
        format.json { render :show, status: :ok, location: @workout }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @workout.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /workouts/1 or /workouts/1.json
  def destroy
    @workout.destroy!

    respond_to do |format|
      format.html { redirect_to workouts_path, status: :see_other, notice: "Workout was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

    def initialize_search
      # session[:filter] = params[:filter]
      params[:intensidad] = nil if params[:intensidad] == ""
      session[:intensidad] = params[:intensidad]
      params[:categoria] = nil if params[:categoria] == ""
      session[:categoria] = params[:categoria]
      params[:duracion] = nil if params[:duracion] == ""
      session[:duracion] = params[:duracion]
    end
    
    # def handle_search_name
    #   if session[:search_name]
    #     @workouts = Workout.where("name LIKE ?", "%#{session[:search_name].titleize}%")
    #   else
    #     @workouts = Workout.all
    #   end
    # end

    def handle_filters
      filters = {}
      filters[:intensity] = session[:intensidad] if session[:intensidad].present?
      filters[:category] = session[:categoria] if session[:categoria].present?
      filters[:duration] = session[:duracion] if session[:duracion].present?

      @workouts = filters.empty? ? Workout.last(9) : Workout.where(filters)
    end


    # Use callbacks to share common setup or constraints between actions.
    def set_workout
      @workout = Workout.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def workout_params
      params[:workout][:material] = params[:workout][:material].reject(&:blank?).join(", ") if params[:workout][:material].is_a?(Array)
      params.require(:workout).permit(:title, :category, :duration, :video_url, :intensity, :material, :day, :cover, :color)
    end

end
