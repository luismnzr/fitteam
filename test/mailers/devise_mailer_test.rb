require "test_helper"

class DeviseMailerTest < ActionMailer::TestCase
  test "restablecer contraseña: en español, con el layout y el remitente de Fitteam" do
    user = users(:member)
    email = Devise::Mailer.reset_password_instructions(user, "token123")

    assert_equal "Restablece tu contraseña", email.subject
    assert_equal [ "hola@anagabyfitteam.com" ], email.from
    assert_includes email[:from].to_s, "Ana Gaby de Fit Team"

    html = email.html_part.body.to_s
    assert_includes html, "Cambiar mi contraseña"
    assert_includes html, "reset_password_token=token123"
    assert_includes html, "email/logo.png"
    assert_includes html, MailerHelper::BRAND_COLOR
    assert_includes email.text_part.body.to_s, "reset_password_token=token123"
  end

  test "aviso de cambio de contraseña" do
    email = Devise::Mailer.password_change(users(:member))
    assert_equal "Tu contraseña cambió", email.subject
    assert_includes email.html_part.body.to_s, MailerHelper::CONTACT_EMAIL
  end
end
