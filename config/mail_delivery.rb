# Cómo se mandan los correos en producción (config/environments/production.rb).
#
# - Con POSTMARK_API_TOKEN: Postmark, igual que los proyectos de Eclipse.
# - Sin él: SMTP con las variables SMTP_* (hoy Mailtrap, que ya tiene el
#   dominio verificado). Basta con SMTP_PASSWORD; el resto trae los valores
#   de Mailtrap. SMTP_USER_NAME también se acepta como usuario.
#
# Así se puede desplegar antes de verificar el dominio en Postmark: al poner
# POSTMARK_API_TOKEN la app cambia sola, sin otro deploy de código.
module MailDelivery
  def self.settings(env = ENV)
    if env["POSTMARK_API_TOKEN"].to_s.strip != ""
      [ :postmark, { api_token: env["POSTMARK_API_TOKEN"] } ]
    else
      [ :smtp, {
        address: env.fetch("SMTP_ADDRESS", "live.smtp.mailtrap.io"),
        port: env.fetch("SMTP_PORT", "587").to_i,
        user_name: env["SMTP_USERNAME"] || env.fetch("SMTP_USER_NAME", "api"),
        password: env["SMTP_PASSWORD"],
        authentication: :login,
        enable_starttls_auto: true,
        open_timeout: 10,
        read_timeout: 10
      } ]
    end
  end
end
