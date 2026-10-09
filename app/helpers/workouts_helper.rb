module WorkoutsHelper
  # Portada de un workout: la miniatura de su video de YouTube.
  def workout_cover_url(workout)
    workout.cover_url
  end

  # style="background-image: …" para las tarjetas y banners del sitio. Debajo
  # va la portada genérica, que se ve si la imagen no carga.
  def workout_cover_style(workout, overlay: nil)
    url = workout_cover_url(workout)
    return unless url

    layers = [ overlay, "url('#{url}')", "url('#{image_path("videoCoverAlt.jpg")}')" ].compact.join(", ")
    "background-image: #{layers}"
  end
end
