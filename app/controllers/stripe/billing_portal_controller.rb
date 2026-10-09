class Stripe::BillingPortalController < ApplicationController
  before_action :authenticate_user!

  def create
    if current_user.stripe_customer_id.blank?
      return redirect_to payments_new_path, alert: "Todavía no tienes una suscripción. Elige un plan para comenzar."
    end

    session = Stripe::BillingPortal::Session.create({
      customer: current_user.stripe_customer_id,
      return_url: edit_user_registration_url
    })
    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error("[Stripe] Portal de pagos falló para #{current_user.email}: #{e.message}")
    redirect_to edit_user_registration_path, alert: "No pudimos abrir el portal de pagos. Intenta de nuevo en unos minutos."
  end
end
