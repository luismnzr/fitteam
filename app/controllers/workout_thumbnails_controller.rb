# Sirve la miniatura de YouTube de un workout desde nuestro dominio. La URL
# de i.ytimg.com lleva el ID del video; si llegara al navegador, cualquiera
# sin plan podría ver la clase directo en YouTube.
class WorkoutThumbnailsController < ActionController::Base
  SIZES = {
    "card" => :card_image_url,
    "cover" => :cover_url
  }.freeze

  def show
    workout = Workout.find(params[:id])
    url = workout.public_send(SIZES.fetch(params[:size]))
    return head :not_found if url.blank?

    # La versión (v) cambia con la URL, así que el navegador puede guardarla
    # mucho tiempo.
    return unless stale?(etag: url, public: true)

    image = Rails.cache.fetch([ "workout-thumbnail", url ], expires_in: 7.days, skip_nil: true) do
      YoutubeThumbnail.download(url)
    end
    return head :not_found unless image

    expires_in 30.days, public: true
    send_data image, type: "image/jpeg", disposition: "inline"
  end
end
