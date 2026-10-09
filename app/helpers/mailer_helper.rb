# Helpers de los correos (layout "mailer"). Mismo diseño base que Eclipse,
# con los colores y el logo de Fitteam.
module MailerHelper
  BRAND_COLOR = "#860847".freeze      # ciruela Fitteam
  BRAND_BACKGROUND = "#F9F8F3".freeze # crema del sitio
  CONTACT_EMAIL = "anagaby.fitteam@gmail.com".freeze

  def brand_color
    BRAND_COLOR
  end

  def brand_background
    BRAND_BACKGROUND
  end

  def contact_email
    CONTACT_EMAIL
  end

  # PNG en public/ (los clientes de correo no muestran SVG) con URL absoluta
  # al dominio de la app.
  def email_logo_url
    URI.join(root_url, "email/logo.png").to_s
  end

  def email_button(text, url, color: brand_color)
    content_tag(:table, role: "presentation", cellpadding: "0", cellspacing: "0", style: "margin: 24px 0;") do
      content_tag(:tr) do
        content_tag(:td, style: "border-radius: 8px; background-color: #{color};") do
          link_to text, url, style: "display: inline-block; padding: 12px 32px; font-size: 14px; font-weight: 600; color: #ffffff; text-decoration: none; border-radius: 8px;", target: "_blank"
        end
      end
    end
  end
end
