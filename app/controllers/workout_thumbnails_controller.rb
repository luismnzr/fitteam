# Sirve la miniatura de YouTube de un workout desde nuestro dominio. La URL
# de i.ytimg.com lleva el ID del video; si llegara al navegador, cualquiera
# sin plan podría ver la clase directo en YouTube.
#
# Las dos medidas salen de la mejor miniatura del video, en 16:9 y sin las
# barras negras: la tarjeta reducida a 800px (nítida en pantallas retina sin
# pesar como la grande) y la portada completa (YouTube da hasta 1280px).
class WorkoutThumbnailsController < ActionController::Base
  MAX_WIDTHS = {
    "card" => 800,
    "cover" => nil
  }.freeze

  # Cambiarla invalida las imágenes ya procesadas (caché y navegadores).
  VERSION = 2

  def show
    workout = Workout.find(params[:id])
    lookup_thumbnail(workout)
    url = workout.cover_url
    return head :not_found if url.blank?

    # La versión (v) cambia con la URL, así que el navegador puede guardarla
    # mucho tiempo.
    return unless stale?(etag: [ url, params[:size], VERSION ], public: true)

    image = Rails.cache.fetch([ "workout-thumbnail", VERSION, params[:size], url ], expires_in: 7.days, skip_nil: true) do
      original = YoutubeThumbnail.download(url)
      original && YoutubeThumbnail.render(original, max_width: MAX_WIDTHS.fetch(params[:size]))
    end
    return head :not_found unless image

    expires_in 30.days, public: true
    send_data image, type: "image/jpeg", disposition: "inline"
  end

  private

  # Workouts que nadie ha guardado en el admin desde que existe
  # thumbnail_url: su mejor miniatura se busca la primera vez que se pide (y
  # a lo más cada hora si YouTube no responde).
  def lookup_thumbnail(workout)
    return if workout.thumbnail_url.present?
    return unless Rails.cache.write([ "workout-thumbnail-lookup", workout.id ], true, unless_exist: true, expires_in: 1.hour)

    workout.ensure_thumbnail_url!
  end
end
