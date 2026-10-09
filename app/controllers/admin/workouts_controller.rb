module Admin
  class WorkoutsController < BaseController
    FILTERS = {
      "scheduled" => "En calendario",
      "premieres" => "Estrenos",
      "strength" => "Strength",
      "unscheduled" => "Sin fecha"
    }.freeze

    before_action :set_workout, only: [ :edit, :update, :destroy ]

    def index
      scope = Workout.all
      scope = scope.where("workouts.title ILIKE ?", "%#{Workout.sanitize_sql_like(params[:q].strip)}%") if params[:q].present?
      scope = scope.where(category: params[:category]) if params[:category].present?
      scope = case params[:filter]
      when "scheduled" then scope.where("workouts.day >= ?", helpers.admin_today)
      when "premieres" then scope.premieres
      when "strength" then scope.where(strength: true)
      when "unscheduled" then scope.where(day: nil)
      else scope
      end
      scope = case params[:sort]
      when "title" then scope.order(:title)
      when "day" then scope.order(Arel.sql("workouts.day DESC NULLS LAST"), created_at: :desc)
      else params[:filter] == "scheduled" ? scope.order(:day) : scope.order(created_at: :desc)
      end

      @workouts = scope.page(params[:page]).per(25)
      ids = @workouts.map(&:id)
      @favorites = Favorite.where(favorited_type: "Workout", favorited_id: ids).group(:favorited_id).count
      @comments = Comment.where(workout_id: ids).group(:workout_id).count
    end

    def new
      @workout = Workout.new(day: params[:day].presence, color: Workout::NORMAL_COLOR)
    end

    def create
      @workout = Workout.new(workout_params)
      if @workout.save
        refresh_thumbnail
        redirect_to admin_workouts_path, notice: with_thumbnail_note("Workout \"#{@workout.title}\" creado.")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @workout.update(workout_params)
        refresh_thumbnail
        redirect_to admin_workouts_path, notice: with_thumbnail_note("Workout \"#{@workout.title}\" actualizado.")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @workout.destroy
      redirect_to admin_workouts_path, notice: "Workout \"#{@workout.title}\" eliminado.", status: :see_other
    end

    private

    def set_workout
      @workout = Workout.find(params[:id])
    end

    # La portada es la miniatura del video de YouTube: se pide cuando cambia
    # el video o si todavía no la tiene.
    def refresh_thumbnail
      return if @workout.thumbnail_url.present? || @workout.youtube_id.blank?

      url = YoutubeThumbnail.fetch(@workout.youtube_id)
      @workout.update_column(:thumbnail_url, url) if url
      @thumbnail_missing = url.nil?
    end

    def with_thumbnail_note(message)
      return message unless @thumbnail_missing

      "#{message} No pudimos comprobar la miniatura en YouTube; mientras tanto se usa la de calidad media."
    end

    def workout_params
      permitted = params.require(:workout).permit(:title, :category, :duration, :video_url, :intensity,
                                                  :day, :strength, :premiere, material: [])
      permitted[:material] = Array(permitted[:material]).reject(&:blank?).join(", ") if permitted.key?(:material)
      if permitted.key?(:premiere)
        premiere = ActiveModel::Type::Boolean.new.cast(permitted.delete(:premiere))
        permitted[:color] = premiere ? Workout::PREMIERE_COLOR : Workout::NORMAL_COLOR
      end
      permitted
    end
  end
end
