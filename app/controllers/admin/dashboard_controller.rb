module Admin
  class DashboardController < BaseController
    CHART_DAYS = 14

    def show
      zone = Time.find_zone(AdminHelper::ADMIN_TIME_ZONE)
      month_start = zone.now.beginning_of_month

      @with_access = User.with_access.count
      @total_users = User.count
      @new_users_month = User.where("created_at >= ?", month_start).count
      @favorites_month = Favorite.where(favorited_type: "Workout").where("created_at >= ?", month_start).count
      @workouts_count = Workout.count
      @unanswered_comments = Comment.unanswered.where("created_at >= ?", 30.days.ago).count
      @expiring_soon = User.with_access.where("subscription_ends_at <= ?", 7.days.from_now).count

      @signups_chart = daily_counts(User.all, zone)
      @favorites_chart = daily_counts(Favorite.where(favorited_type: "Workout"), zone)

      # La semana del calendario: el "Workout del día" del sitio sale de aquí.
      today = zone.today
      @week = (today..(today + 6)).to_a
      @week_workouts = Workout.where(day: @week).order(:created_at).group_by(&:day)

      top = Favorite.where(favorited_type: "Workout").where("created_at >= ?", month_start)
                    .group(:favorited_id).order("count_all DESC").limit(5).count
      workouts = Workout.where(id: top.keys).index_by(&:id)
      @top_workouts = top.filter_map { |id, count| [ workouts[id], count ] if workouts[id] }

      @recent_comments = Comment.roots.includes(:workout, :user, :replies).order(created_at: :desc).limit(5)
      @recent_users = User.order(created_at: :desc).limit(5)
    end

    private

    # Conteo por día (zona de México) de los últimos CHART_DAYS días, con los
    # días sin actividad en cero para que la gráfica no tenga huecos.
    def daily_counts(scope, zone)
      first_day = zone.today - (CHART_DAYS - 1)
      table = scope.table_name
      local_day = "DATE(#{table}.created_at AT TIME ZONE 'UTC' AT TIME ZONE '#{zone.tzinfo.identifier}')"
      counts = scope.where("#{table}.created_at >= ?", first_day.in_time_zone(zone)).group(Arel.sql(local_day)).count
      (first_day..zone.today).map { |day| { date: day, count: counts[day] || 0 } }
    end
  end
end
