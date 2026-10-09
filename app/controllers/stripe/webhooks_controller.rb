# Webhook de Stripe: mantiene el acceso de cada usuaria al día con su
# suscripción. Solo acepta eventos firmados con STRIPE_WEBHOOK_KEY.
class Stripe::WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Estados con los que la suscripción sigue dando acceso. past_due conserva
  # el acceso mientras Stripe reintenta el cobro.
  ACCESS_STATUSES = %w[active trialing past_due].freeze

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
    when "customer.subscription.created", "customer.subscription.updated"
      sync_subscription(event.data.object)
    when "customer.subscription.deleted"
      sync_subscription(event.data.object, deleted: true)
    end

    render json: { message: "success" }
  end

  private

  def link_customer(customer)
    return if customer.email.blank?

    user = User.find_by(email: customer.email.downcase)
    user.update(stripe_customer_id: customer.id) if user && user.stripe_customer_id.blank?
  end

  def sync_subscription(subscription, deleted: false)
    user = User.find_by(stripe_customer_id: subscription.customer)
    unless user
      Rails.logger.info("[Stripe webhook] Sin usuaria para el cliente #{subscription.customer}")
      return
    end

    if !deleted && ACCESS_STATUSES.include?(subscription.status)
      user.update(
        subscription_id: subscription.id,
        subscription_status: subscription.status,
        subscription_ends_at: period_end(subscription) || user.subscription_ends_at
      )
    elsif user.subscription_id.blank? || user.subscription_id == subscription.id
      # Solo la suscripción actual quita el acceso: si se cancela una vieja,
      # la nueva sigue igual.
      user.update(
        subscription_id: (deleted ? nil : subscription.id),
        subscription_status: (deleted ? "canceled" : subscription.status),
        subscription_ends_at: [ user.subscription_ends_at, Time.current ].compact.min
      )
    end
  end

  # Desde la API 2025-03-31 el fin del periodo vive en cada item de la
  # suscripción; en versiones anteriores, en la suscripción.
  def period_end(subscription)
    timestamp = subscription["current_period_end"] ||
                subscription["items"]&.[]("data")&.first&.[]("current_period_end")
    timestamp ? Time.zone.at(timestamp) : nil
  end
end
