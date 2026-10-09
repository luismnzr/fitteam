module WorkoutsHelper
  # Portada de un workout: la imagen subida si vive en el almacenamiento
  # actual; si no (sin portada, o subida al bucket anterior), la miniatura de
  # su video de YouTube.
  def workout_cover_url(workout)
    if workout.cover.attached? && workout.cover.blob.service_name == ActiveStorage::Blob.service.name.to_s
      rails_blob_url(workout.cover)
    else
      workout.youtube_thumbnail_url
    end
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
