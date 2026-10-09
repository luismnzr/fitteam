require "net/http"

# Miniatura de un video de YouTube: es la portada de los workouts (ya no se
# suben portadas a S3). No usa la API de YouTube: las miniaturas viven en
# i.ytimg.com con URLs fijas por tamaño.
#
# Elige la de mejor calidad que exista para el video. hqdefault existe para
# todos los videos; maxresdefault (1280px) y sddefault (640px) solo para los
# que se subieron con esa resolución.
#
# Nunca truena: si YouTube no responde, regresa nil y el sitio usa hqdefault
# (Workout#cover_url).
class YoutubeThumbnail
  SIZES = %w[maxresdefault sddefault hqdefault].freeze
  TIMEOUT = 4

  def self.fetch(video_id)
    return if video_id.blank?

    SIZES.each do |size|
      url = "https://i.ytimg.com/vi/#{video_id}/#{size}.jpg"
      return url if exists?(url)
    end
    nil
  rescue StandardError => e
    Rails.logger.warn("[YouTube] Sin miniatura para #{video_id}: #{e.class}: #{e.message}")
    nil
  end

  # YouTube responde 404 (con una imagen gris de 120x90) cuando ese tamaño no
  # existe.
  def self.exists?(url)
    uri = URI(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      http.head(uri.request_uri)
    end
    response.is_a?(Net::HTTPSuccess)
  end
end
