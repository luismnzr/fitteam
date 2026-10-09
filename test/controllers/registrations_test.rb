require "test_helper"

# Antes el formulario de cuenta aceptaba admin, subscription_ends_at, etc.:
# cualquiera podía darse acceso o volverse admin.
class RegistrationsTest < ActionDispatch::IntegrationTest
  test "editar la cuenta no permite darse acceso ni volverse admin" do
    user = users(:guest)
    sign_in user
    put user_registration_url, params: {
      user: { name: "Nuevo nombre", admin: "1", subscription_ends_at: "2099-01-01", stripe_customer_id: "cus_hack",
              subscription_status: "active", current_password: "password123" }
    }
    user.reload
    assert_equal "Nuevo nombre", user.name
    assert_not user.admin?
    assert_not user.active?
    assert_nil user.stripe_customer_id
  end

  test "el registro solo acepta nombre, correo y contraseña" do
    post user_registration_url, params: {
      user: { name: "Nueva", email: "nueva@example.com", password: "password123", password_confirmation: "password123",
              admin: "1", subscription_ends_at: "2099-01-01" }
    }
    user = User.find_by!(email: "nueva@example.com")
    assert_not user.admin?
    assert_not user.active?
  end
end
