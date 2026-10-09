require "test_helper"

class Admin::UsersTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "filtros por acceso" do
    get admin_users_url(filter: "with_access")
    assert_includes response.body, users(:member).email
    assert_not_includes response.body, users(:guest).email

    get admin_users_url(filter: "without_access")
    assert_includes response.body, users(:guest).email
    assert_not_includes response.body, users(:member).email

    get admin_users_url(q: "sin plan")
    assert_includes response.body, users(:guest).email
  end

  test "dar acceso de cortesía hasta una fecha" do
    user = users(:guest)
    patch admin_user_url(user), params: { user: { name: "Cortesía", email: user.email, subscription_ends_at: 1.month.from_now.to_date.to_s } }
    assert_redirected_to admin_user_url(user)
    user.reload
    assert user.active?
    assert_equal 1.month.from_now.to_date, user.subscription_ends_at.to_date
    assert_equal 1.month.from_now.end_of_day.to_i, user.subscription_ends_at.to_i
  end

  test "guardar sin cambiar la fecha conserva el vencimiento de Stripe" do
    user = users(:member)
    ends_at = user.subscription_ends_at
    patch admin_user_url(user), params: { user: { name: "Otro nombre", email: user.email, subscription_ends_at: ends_at.to_date.to_s } }
    user.reload
    assert_equal "Otro nombre", user.name
    assert_equal ends_at.to_i, user.subscription_ends_at.to_i
  end

  test "quitar el acceso dejando la fecha vacía" do
    user = users(:member)
    patch admin_user_url(user), params: { user: { email: user.email, subscription_ends_at: "" } }
    assert_not user.reload.active?
  end

  test "no puede quitarse su propio rol de admin" do
    admin = users(:admin)
    patch admin_user_url(admin), params: { user: { email: admin.email, admin: "0" } }
    assert_response :unprocessable_entity
    assert admin.reload.admin?
  end

  test "enviar correo para nueva contraseña" do
    assert_emails 1 do
      post send_password_reset_admin_user_url(users(:member))
    end
    assert_redirected_to admin_user_url(users(:member))
  end
end
