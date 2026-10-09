module Admin
  # Calendario mensual de workouts (columna day). Es lo que alimenta el
  # "Workout del día" de la home y el calendario público.
  class CalendarController < BaseController
    def show
      today = helpers.admin_today
      @month = begin
        Date.strptime(params[:month].to_s, "%Y-%m")
      rescue Date::Error
        today.beginning_of_month
      end
      first = @month.beginning_of_month
      last = @month.end_of_month
      # Semanas de lunes a domingo, como el calendario del sitio.
      @days = (first.beginning_of_week(:monday)..last.end_of_week(:monday)).to_a
      @workouts = Workout.where(day: @days.first..@days.last).order(:created_at).group_by(&:day)
      @today = today
    end
  end
end
