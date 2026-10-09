module WorkoutsHelper
  # style="background-image: …" para los banners y portadas grandes del sitio.
  # Debajo va la portada genérica, que se ve si la imagen no carga.
  def workout_cover_style(workout, overlay: nil)
    background_style(workout.cover_url, overlay: overlay)
  end

  # Igual, para las tarjetas del catálogo: miniatura de 480px agrandada a
  # 134% del alto para que las barras negras de hqdefault queden fuera.
  def workout_card_style(workout)
    style = background_style(workout.card_image_url)
    style && "#{style}; background-size: auto 134%, cover"
  end

  private

  def background_style(url, overlay: nil)
    return unless url

    layers = [ overlay, "url('#{url}')", "url('#{image_path("videoCoverAlt.jpg")}')" ].compact.join(", ")
    "background-image: #{layers}"
  end
end
