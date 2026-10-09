class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # Solo datos del perfil. El acceso, la suscripción y el rol de admin no se
  # aceptan desde los formularios de cuenta (antes cualquiera podía darse
  # acceso o volverse admin editando su cuenta); los maneja el admin y Stripe.
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end
end
