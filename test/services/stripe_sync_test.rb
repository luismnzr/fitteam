require "test_helper"

class StripeSyncTest < ActiveSupport::TestCase
  setup do
    @member = users(:member)
    @guest = users(:guest)
  end

  test "una suscripción activa da acceso hasta el fin de su periodo" do
    @guest.update!(stripe_customer_id: "cus_guest")
    ends_at = 31.days.from_now
    with_stripe_subscriptions([ stripe_subscription(id: "sub_g", customer: "cus_guest", ends_at: ends_at) ]) do
      assert_equal :granted, StripeSync.sync_customer("cus_guest").kind
    end
    @guest.reload
    assert @guest.active?
    assert_equal "sub_g", @guest.subscription_id
    assert_equal "active", @guest.subscription_status
    assert_equal ends_at.to_i, @guest.subscription_ends_at.to_i
  end

  test "con dos suscripciones manda la que da acceso por más tiempo" do
    subscriptions = [
      stripe_subscription(id: "sub_vieja", customer: "cus_member", status: "canceled", ends_at: 90.days.from_now, created: 1.year.ago),
      stripe_subscription(id: "sub_member", customer: "cus_member", ends_at: 20.days.from_now),
      stripe_subscription(id: "sub_anual", customer: "cus_member", status: "trialing", ends_at: 300.days.from_now)
    ]
    with_stripe_subscriptions(subscriptions) { StripeSync.sync_customer("cus_member") }
    assert_equal "sub_anual", @member.reload.subscription_id
    assert_equal "trialing", @member.subscription_status
  end

  test "lee lo que dice Stripe ahora, no lo que traía el evento" do
    canceled = stripe_subscription(id: "sub_member", customer: "cus_member", status: "canceled", ends_at: 20.days.from_now)
    with_stripe_subscriptions([ canceled ]) do
      assert_equal :revoked, StripeSync.sync_customer("cus_member").kind
    end
    @member.reload
    assert_not @member.active?
    assert_equal "canceled", @member.subscription_status
    assert_nil @member.subscription_id
  end

  test "past_due conserva el acceso y unpaid lo quita" do
    with_stripe_subscriptions([ stripe_subscription(id: "sub_member", customer: "cus_member", status: "past_due", ends_at: 25.days.from_now) ]) do
      StripeSync.sync_customer("cus_member")
    end
    assert @member.reload.active?

    with_stripe_subscriptions([ stripe_subscription(id: "sub_member", customer: "cus_member", status: "unpaid", ends_at: 25.days.from_now) ]) do
      StripeSync.sync_customer("cus_member")
    end
    assert_not @member.reload.active?
    assert_equal "unpaid", @member.subscription_status
  end

  test "lee el fin del periodo de los items (API de Stripe 2025-03-31 en adelante)" do
    ends_at = 40.days.from_now.to_i
    subscription = Stripe::Subscription.construct_from(
      id: "sub_member", object: "subscription", customer: "cus_member", status: "active", created: Time.current.to_i,
      items: { object: "list", data: [ { id: "si_1", object: "subscription_item", current_period_end: ends_at } ] }
    )
    with_stripe_subscriptions([ subscription ]) { StripeSync.sync_customer("cus_member") }
    assert_equal ends_at, @member.reload.subscription_ends_at.to_i
  end

  test "un acceso de cortesía no se toca aunque haya suscripciones viejas" do
    user = User.create!(email: "cortesia@example.com", password: "password123", stripe_customer_id: "cus_cortesia",
                        subscription_ends_at: 60.days.from_now)
    old = stripe_subscription(id: "sub_2024", customer: "cus_cortesia", status: "canceled", ends_at: 1.year.ago, created: 2.years.ago)
    with_stripe_subscriptions([ old ]) do
      assert_equal :courtesy, StripeSync.sync_customer("cus_cortesia").kind
    end
    assert user.reload.active?
  end

  test "quita el acceso que guardó el webhook anterior si la suscripción ya no está activa" do
    # El webhook anterior guardaba el fin del periodo aunque la suscripción
    # quedara sin pagar, y no guardaba subscription_id.
    ends_at = 25.days.from_now
    user = User.create!(email: "legacy@example.com", password: "password123", stripe_customer_id: "cus_legacy",
                        subscription_ends_at: ends_at, subscription_status: "past_due")
    unpaid = stripe_subscription(id: "sub_legacy", customer: "cus_legacy", status: "unpaid", ends_at: ends_at)
    with_stripe_subscriptions([ unpaid ]) do
      assert_equal :revoked, StripeSync.sync_customer("cus_legacy").kind
    end
    assert_not user.reload.active?
  end

  test "liga por correo un cliente que paga y que nadie tiene guardado" do
    customer = stripe_customer("cus_dup", @guest.email)
    with_stripe_subscriptions([ stripe_subscription(id: "sub_dup", customer: "cus_dup") ], customers: [ customer ]) do
      assert_equal :granted, StripeSync.sync_customer("cus_dup").kind
    end
    assert_equal "cus_dup", @guest.reload.stripe_customer_id
    assert @guest.active?
  end

  test "no cambia de cliente a quien ya paga con otro" do
    customer = stripe_customer("cus_otro", @member.email)
    subscriptions = [ stripe_subscription(id: "sub_member", customer: "cus_member"), stripe_subscription(id: "sub_otro", customer: "cus_otro") ]
    with_stripe_subscriptions(subscriptions, customers: [ customer ]) do
      assert_nil StripeSync.sync_customer("cus_otro")
    end
    assert_equal "cus_member", @member.reload.stripe_customer_id
  end

  test "sync_user busca el cliente por correo si no lo tiene guardado" do
    customers = [ stripe_customer("cus_sin_subs", @guest.email), stripe_customer("cus_paga", @guest.email) ]
    with_stripe_subscriptions([ stripe_subscription(id: "sub_paga", customer: "cus_paga") ], customers: customers) do
      result = StripeSync.sync_user(@guest)
      assert_equal :granted, result.kind
    end
    assert_equal "cus_paga", @guest.reload.stripe_customer_id
  end

  test "sync_user sin cliente en Stripe" do
    with_stripe_subscriptions([]) do
      assert_equal :not_found, StripeSync.sync_user(@guest).kind
    end
  end

  test "sync_all compara a todas, y en simulación no cambia nada" do
    @guest.update!(stripe_customer_id: "cus_guest")
    courtesy = User.create!(email: "regalo@example.com", password: "password123", subscription_ends_at: 10.days.from_now)
    subscriptions = [
      stripe_subscription(id: "sub_member", customer: "cus_member", status: "canceled", ends_at: 20.days.from_now),
      stripe_subscription(id: "sub_g", customer: "cus_guest", ends_at: 30.days.from_now),
      stripe_subscription(id: "sub_huerfana", customer: "cus_huerfano", email: "nadie@example.com"),
      stripe_subscription(id: "sub_viejo", customer: "cus_sin_usuaria", status: "canceled", ends_at: 2.years.ago)
    ]
    calls = []

    report = with_stripe_subscriptions(subscriptions, calls: calls) { StripeSync.sync_all(dry_run: true) }

    assert_equal 1, calls.size, "lee las suscripciones de Stripe una sola vez"
    assert_equal [ @guest ], report.of(:granted).map(&:user)
    assert_equal [ @member ], report.of(:revoked).map(&:user)
    assert_equal [ [ "cus_huerfano", "nadie@example.com" ] ], report.orphans.map { |orphan| orphan.first(2) }
    assert_includes report.unlinked_with_access, courtesy
    assert @member.reload.active?, "la simulación no cambia nada"
    assert_not @guest.reload.active?

    text = report.to_text(dry_run: true, mode: "test")
    assert_match "Ganan acceso (1)", text
    assert_match "guest@example.com: sin acceso → hasta", text
    assert_match "Pierden acceso (1)", text
    assert_match "Pagan en Stripe y no tienen cuenta en la app (1)", text
    assert_match "regalo@example.com", text
    assert_match "Simulación: no se cambió nada.", text

    with_stripe_subscriptions(subscriptions) { StripeSync.sync_all }
    assert_not @member.reload.active?
    assert @guest.reload.active?
  end

  test "sync_all liga al cliente que paga en lugar del que no y detecta dos clientes pagando" do
    @guest.update!(stripe_customer_id: "cus_guest_viejo")
    subscriptions = [
      stripe_subscription(id: "sub_nueva", customer: "cus_guest_nuevo", email: @guest.email),
      stripe_subscription(id: "sub_member", customer: "cus_member", email: @member.email),
      stripe_subscription(id: "sub_member_2", customer: "cus_member_2", email: @member.email)
    ]
    report = with_stripe_subscriptions(subscriptions) { StripeSync.sync_all }

    assert_equal "cus_guest_nuevo", @guest.reload.stripe_customer_id
    assert @guest.active?
    assert_equal [ @guest ], report.relinked.map(&:user)
    assert_equal [ [ @member, "cus_member", "cus_member_2" ] ], report.conflicts
  end

  test "no aplica cambios en producción con una llave de pruebas" do
    previous = Stripe.api_key
    Stripe.api_key = "sk_test_123"
    Rails.env.stub(:production?, true) do
      assert_raises(StripeSync::Error) { StripeSync.run(dry_run: false, io: StringIO.new) }
    end
  ensure
    Stripe.api_key = previous
  end

  test "no quita el acceso a muchas de golpe sin FORCE" do
    previous = Stripe.api_key
    Stripe.api_key = "sk_test_123"
    users = 6.times.map do |i|
      User.create!(email: "paga#{i}@example.com", password: "password123", stripe_customer_id: "cus_#{i}",
                   subscription_id: "sub_#{i}", subscription_ends_at: 20.days.from_now)
    end
    canceled = users.each_with_index.map { |_, i| stripe_subscription(id: "sub_#{i}", customer: "cus_#{i}", status: "canceled") }

    with_stripe_subscriptions(canceled) do
      assert_raises(StripeSync::Error) { StripeSync.run(dry_run: false, io: StringIO.new) }
      assert users.all? { |user| user.reload.active? }

      StripeSync.run(dry_run: false, force: true, io: StringIO.new)
    end
    assert users.none? { |user| user.reload.active? }
  ensure
    Stripe.api_key = previous
  end
end
