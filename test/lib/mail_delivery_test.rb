require "test_helper"
require Rails.root.join("config/mail_delivery").to_s

class MailDeliveryTest < ActiveSupport::TestCase
  test "con POSTMARK_API_TOKEN usa Postmark" do
    method, settings = MailDelivery.settings("POSTMARK_API_TOKEN" => "pm-token", "SMTP_PASSWORD" => "smtp")
    assert_equal :postmark, method
    assert_equal({ api_token: "pm-token" }, settings)
  end

  test "sin Postmark usa el SMTP de Mailtrap con la contraseña de SMTP_PASSWORD" do
    method, settings = MailDelivery.settings("SMTP_PASSWORD" => "mt-token", "POSTMARK_API_TOKEN" => " ")
    assert_equal :smtp, method
    assert_equal "live.smtp.mailtrap.io", settings[:address]
    assert_equal 587, settings[:port]
    assert_equal "api", settings[:user_name]
    assert_equal "mt-token", settings[:password]
  end

  test "las variables SMTP_* permiten otro servidor" do
    _, settings = MailDelivery.settings("SMTP_ADDRESS" => "smtp.example.com", "SMTP_PORT" => "2525", "SMTP_USERNAME" => "user", "SMTP_PASSWORD" => "pw")
    assert_equal [ "smtp.example.com", 2525, "user" ], settings.values_at(:address, :port, :user_name)
  end

  test "acepta SMTP_USER_NAME y pone timeouts" do
    _, settings = MailDelivery.settings("SMTP_USER_NAME" => "otro", "SMTP_PASSWORD" => "pw")
    assert_equal "otro", settings[:user_name]
    assert_equal 10, settings[:open_timeout]
    assert_equal 10, settings[:read_timeout]
  end
end
