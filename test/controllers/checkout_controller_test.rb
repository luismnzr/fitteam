require "test_helper"

class CheckoutControllerTest < ActionDispatch::IntegrationTest
  test "pide sesión" do
    post stripe_checkout_url(plan: "mensual")
    assert_redirected_to new_user_session_url
  end

  test "solo acepta los planes de la página de planes" do
    sign_in users(:member)
    post stripe_checkout_url(price_id: "price_otro_mas_barato")
    assert_redirected_to payments_new_url
    assert_equal "Elige uno de los planes.", flash[:alert]
  end

  test "abre Stripe Checkout con el precio del plan y el cliente de la usuaria" do
    sign_in users(:member)
    received = nil
    fake_create = lambda do |params|
      received = params
      Struct.new(:url).new("https://checkout.stripe.com/c/pay/cs_test")
    end

    Stripe::Checkout::Session.stub(:create, fake_create) do
      post stripe_checkout_url(plan: "anual")
    end

    assert_redirected_to "https://checkout.stripe.com/c/pay/cs_test"
    assert_equal Plan.price_id("anual"), received[:line_items].first[:price]
    assert_equal "cus_member", received[:customer]
    assert_equal users(:member).id, received[:client_reference_id]
  end

  test "portal de pagos sin cliente de Stripe manda a los planes" do
    sign_in users(:guest)
    post stripe_billing_portal_url
    assert_redirected_to payments_new_url
  end

  test "al volver del pago da acceso sin esperar al webhook" do
    user = users(:guest)
    user.update!(stripe_customer_id: "cus_guest")
    sign_in user
    with_stripe_subscriptions([ stripe_subscription(id: "sub_g", customer: "cus_guest") ]) do
      get stripe_checkout_success_url
    end
    assert_redirected_to workouts_url
    assert_match "ya está activa", flash[:notice]
    assert user.reload.active?
  end

  test "si Stripe no responde al volver del pago, el webhook da el acceso" do
    user = users(:guest)
    user.update!(stripe_customer_id: "cus_guest")
    sign_in user
    Stripe::Subscription.stub(:list, ->(*) { raise Stripe::APIConnectionError, "sin conexión" }) do
      get stripe_checkout_success_url
    end
    assert_redirected_to workouts_url
    assert_match "se está activando", flash[:notice]
  end
end
