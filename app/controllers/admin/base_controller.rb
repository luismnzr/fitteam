# Base de todo el admin: exige sesión y que la usuaria sea admin. Todas las
# acciones de escritura de contenido viven en controladores que heredan de aquí.
module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :require_admin

    private

    def require_admin
      return if current_user.admin?

      redirect_to root_path, alert: "No tienes acceso a esa sección."
    end
  end
end
