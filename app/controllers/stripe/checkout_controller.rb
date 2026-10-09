class Stripe::CheckoutController < ApplicationController
  before_action :authenticate_user!, only: :checkout

  def checkout
    price_id = Plan.price_id(params[:plan])
    return redirect_to(payments_new_path, alert: "Elige uno de los planes.") unless price_id

    session = Stripe::Checkout::Session.create({
      customer: current_user.ensure_stripe_customer!,
      client_reference_id: current_user.id,
      mode: "subscription",
      allow_promotion_codes: true,
      line_items: [ { quantity: 1, price: price_id } ],
      success_url: stripe_checkout_success_url,
      cancel_url: stripe_checkout_cancel_url
    })
    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error("[Stripe] Checkout falló para #{current_user.email}: #{e.message}")
    redirect_to payments_new_path, alert: "No pudimos abrir el pago. Intenta de nuevo en unos minutos."
  end

  # El acceso lo da el webhook de Stripe (puede tardar unos segundos).
  def success
    redirect_to workouts_path, notice: "¡Gracias! Tu suscripción se está activando; en unos segundos tendrás acceso a todas las clases."
  end

  def cancel
    redirect_to payments_new_path, alert: "El pago no se completó."
  end
end
