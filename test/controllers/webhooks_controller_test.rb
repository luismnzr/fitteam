require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  SECRET = "whsec_test".freeze

  setup do
    @previous_secret = ENV["STRIPE_WEBHOOK_KEY"]
    ENV["STRIPE_WEBHOOK_KEY"] = SECRET
    @member = users(:member)
  end

  teardown do
    ENV["STRIPE_WEBHOOK_KEY"] = @previous_secret
  end

  test "rechaza eventos sin firma válida" do
    post "/stripe/webhooks", params: event("customer.subscription.deleted", subscription).to_json,
                             headers: { "Content-Type" => "application/json", "Stripe-Signature" => "t=1,v1=falsa" }
    assert_response :bad_request
    assert @member.reload.active?
  end

  test "sin STRIPE_WEBHOOK_KEY no procesa nada y pide reintento" do
    ENV["STRIPE_WEBHOOK_KEY"] = nil
    deliver event("customer.subscription.deleted", subscription)
    assert_response :service_unavailable
    assert @member.reload.active?
  end

  test "una suscripción activa da acceso hasta el fin del periodo" do
    user = users(:guest)
    user.update!(stripe_customer_id: "cus_guest")
    period_end = 30.days.from_now.to_i
    deliver event("customer.subscription.created", subscription(id: "sub_new", customer: "cus_guest", current_period_end: period_end))

    assert_response :success
    user.reload
    assert user.active?
    assert_equal "sub_new", user.subscription_id
    assert_equal "active", user.subscription_status
    assert_equal period_end, user.subscription_ends_at.to_i
  end

  test "lee el fin del periodo de los items (API de Stripe 2025-03-31 en adelante)" do
    period_end = 40.days.from_now.to_i
    payload = subscription(status: "active").except(:current_period_end).merge(items: { object: "list", data: [ { id: "si_1", current_period_end: period_end } ] })
    deliver event("customer.subscription.updated", payload)
    assert_equal period_end, @member.reload.subscription_ends_at.to_i
  end

  test "pago pendiente conserva el acceso" do
    deliver event("customer.subscription.updated", subscription(status: "past_due", current_period_end: 25.days.from_now.to_i))
    @member.reload
    assert @member.active?
    assert_equal "past_due", @member.subscription_status
  end

  test "sin pagar quita el acceso" do
    deliver event("customer.subscription.updated", subscription(status: "unpaid"))
    @member.reload
    assert_not @member.active?
    assert_equal "unpaid", @member.subscription_status
  end

  test "cancelada quita el acceso" do
    deliver event("customer.subscription.deleted", subscription(status: "canceled"))
    @member.reload
    assert_not @member.active?
    assert_equal "canceled", @member.subscription_status
    assert_nil @member.subscription_id
  end

  test "cancelar una suscripción vieja no quita el acceso de la actual" do
    deliver event("customer.subscription.deleted", subscription(id: "sub_vieja", status: "canceled"))
    @member.reload
    assert @member.active?
    assert_equal "sub_member", @member.subscription_id
  end

  test "clientes desconocidos no rompen el webhook" do
    deliver event("customer.subscription.updated", subscription(customer: "cus_desconocido"))
    assert_response :success
  end

  test "customer.created liga el cliente por correo" do
    user = users(:guest)
    deliver event("customer.created", { id: "cus_nuevo", object: "customer", email: user.email.upcase })
    assert_equal "cus_nuevo", user.reload.stripe_customer_id
  end

  private

  def subscription(id: "sub_member", customer: "cus_member", status: "active", current_period_end: 30.days.from_now.to_i)
    { id: id, object: "subscription", customer: customer, status: status, current_period_end: current_period_end }
  end

  def event(type, object)
    { id: "evt_#{SecureRandom.hex(4)}", object: "event", type: type, data: { object: object } }
  end

  def deliver(payload)
    body = payload.to_json
    timestamp = Time.now.to_i
    signature = Stripe::Webhook::Signature.compute_signature(Time.at(timestamp), body, SECRET)
    post "/stripe/webhooks", params: body,
                             headers: { "Content-Type" => "application/json", "Stripe-Signature" => "t=#{timestamp},v1=#{signature}" }
  end
end
