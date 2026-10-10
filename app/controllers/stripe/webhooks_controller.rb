# Webhook de Stripe: mantiene el acceso de cada usuaria al día con su
# suscripción. Solo acepta eventos firmados con STRIPE_WEBHOOK_KEY.
class Stripe::WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    secret = ENV["STRIPE_WEBHOOK_KEY"].presence || ENV["STRIPE_WEBHOOK_SECRET"].presence
    if secret.blank?
      # 503 para que Stripe reintente cuando la variable ya esté puesta.
      Rails.logger.error("[Stripe webhook] Falta STRIPE_WEBHOOK_KEY; evento rechazado")
      return head :service_unavailable
    end

    begin
      event = Stripe::Webhook.construct_event(request.body.read, request.env["HTTP_STRIPE_SIGNATURE"], secret)
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      Rails.logger.warn("[Stripe webhook] Rechazado: #{e.class}: #{e.message}")
      return head :bad_request
    end

    case event.type
    when "customer.created"
      link_customer(event.data.object)
    when "customer.subscription.created", "customer.subscription.updated", "customer.subscription.deleted"
      # No se usa la suscripción del evento: StripeSync vuelve a leer de
      # Stripe las de la clienta, así un evento viejo que llega tarde no
      # devuelve un acceso ya cancelado.
      StripeSync.sync_customer(event.data.object.customer)
    end

    render json: { message: "success" }
  rescue Stripe::StripeError => e
    # 500 para que Stripe reintente el evento.
    Rails.logger.error("[Stripe webhook] #{event&.type}: #{e.class}: #{e.message}")
    head :internal_server_error
  end

  private

  def link_customer(customer)
    return if customer.email.blank?

    user = User.find_by(email: customer.email.downcase)
    user.update(stripe_customer_id: customer.id) if user && user.stripe_customer_id.blank?
  end
end
