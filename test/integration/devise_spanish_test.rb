require "test_helper"

class DeviseSpanishTest < ActionDispatch::IntegrationTest
  test "login fallido en español" do
    post user_session_url, params: { user: { email: "member@example.com", password: "mal" } }
    assert_includes response.body, "Correo o contraseña incorrectos."
  end

  test "pedir restablecer contraseña" do
    post user_password_url, params: { user: { email: "member@example.com" } }
    follow_redirect!
    assert_includes response.body, "En unos minutos te llegará un correo"
  end

  test "errores del registro en español" do
    post user_registration_url, params: { user: { name: "X", email: "member@example.com", password: "123", password_confirmation: "456" } }
    assert_includes response.body, "Revisa lo siguiente:"
    assert_includes response.body, "Correo electrónico ya está registrado"
    assert_includes response.body, "Contraseña debe tener al menos 6 caracteres"
  end

  test "el correo de restablecer contraseña sale en segundo plano (un fallo de SMTP no rompe la página)" do
    assert_enqueued_emails 1 do
      post user_password_url, params: { user: { email: "member@example.com" } }
    end
    assert_redirected_to new_user_session_url
  end
end
