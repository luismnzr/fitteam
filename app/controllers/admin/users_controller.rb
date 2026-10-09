module Admin
  class UsersController < BaseController
    FILTERS = {
      "with_access" => "Con acceso",
      "without_access" => "Sin acceso",
      "expiring" => "Vencen en 7 días",
      "admins" => "Admins"
    }.freeze

    before_action :set_user, only: [ :show, :edit, :update, :send_password_reset, :sync_stripe ]

    def index
      scope = User.all
      if params[:q].present?
        term = "%#{User.sanitize_sql_like(params[:q].strip)}%"
        scope = scope.where("users.name ILIKE :t OR users.email ILIKE :t", t: term)
      end
      scope = case params[:filter]
      when "with_access" then scope.with_access
      when "without_access" then scope.without_access
      when "expiring" then scope.with_access.where("users.subscription_ends_at <= ?", 7.days.from_now)
      when "admins" then scope.where(admin: true)
      else scope
      end
      scope = case params[:sort]
      when "name" then scope.order(Arel.sql("LOWER(COALESCE(users.name, users.email))"))
      when "access" then scope.order(Arel.sql("users.subscription_ends_at DESC NULLS LAST"))
      else scope.order(created_at: :desc)
      end

      @users = scope.page(params[:page]).per(25)
      @favorites = Favorite.where(user_id: @users.map(&:id)).group(:user_id).count
    end

    def show
      @favorites = @user.favorite_workouts.order("favorites.created_at DESC").limit(10)
      @favorites_count = @user.favorites.count
      @comments = @user.comments.includes(:workout).order(created_at: :desc).limit(5)
      @comments_count = @user.comments.count
    end

    def edit
    end

    def update
      attrs = user_params
      if @user == current_user && attrs.key?(:admin) && !ActiveModel::Type::Boolean.new.cast(attrs[:admin])
        @user.assign_attributes(attrs.except(:admin))
        @user.errors.add(:base, "No puedes quitarte tu propio rol de admin.")
        return render :edit, status: :unprocessable_entity
      end

      if @user.update(attrs)
        redirect_to admin_user_path(@user), notice: "Datos de #{@user.display_name} actualizados."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def send_password_reset
      @user.send_reset_password_instructions
      redirect_to admin_user_path(@user), notice: "Enviamos a #{@user.email} un correo para restablecer su contraseña."
    end

    def sync_stripe
      if Stripe.api_key.blank?
        return redirect_to admin_user_path(@user), alert: "Falta STRIPE_SECRET_KEY: no se puede consultar Stripe."
      end

      result = StripeSync.sync_user(@user)
      redirect_to admin_user_path(@user), notice: sync_message(result)
    rescue Stripe::StripeError => e
      redirect_to admin_user_path(@user), alert: "Stripe no respondió (#{e.message}). Intenta de nuevo en unos minutos."
    end

    private

    def sync_message(result)
      ends_at = helpers.admin_date(result.ends_at_after)
      message = case result.kind
      when :not_found then "No encontramos a #{@user.email} en Stripe."
      when :granted then "Stripe dice que tiene una suscripción activa: ya tiene acceso hasta el #{ends_at}."
      when :revoked then "No tiene una suscripción activa en Stripe: le quitamos el acceso."
      when :extended, :shortened then "Su acceso ahora termina el #{ends_at}, como en Stripe."
      when :courtesy then "No tiene una suscripción activa en Stripe; su acceso hasta el #{ends_at} es de cortesía y se queda igual."
      else "Ya estaba al día con Stripe."
      end
      linked = result.customer_after.present? && result.customer_after != result.customer_before
      linked ? "#{message} Quedó ligada a su cliente de Stripe." : message
    end

    def set_user
      @user = User.find(params[:id])
    end

    # "Acceso hasta" llega como fecha: el acceso dura hasta el final de ese día
    # (hora de México). Si la fecha no cambió se conserva la hora exacta que
    # puso Stripe.
    def user_params
      permitted = params.require(:user).permit(:name, :email, :admin, :subscription_ends_at)
      if permitted.key?(:subscription_ends_at)
        date = Date.parse(permitted[:subscription_ends_at]) rescue nil
        if date && date == @user.subscription_ends_at&.to_date
          permitted.delete(:subscription_ends_at)
        else
          permitted[:subscription_ends_at] = date&.end_of_day
        end
      end
      permitted
    end
  end
end
