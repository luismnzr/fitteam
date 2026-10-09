module WorkoutsHelper
  CATEGORY_PATHS = {
    "Lower Body" => :lowerbody_path,
    "Upper Body" => :upperbody_path,
    "ABS and Core" => :abscore_path,
    "Glutes and Hips" => :gluteships_path,
    "Full Body" => :fullbody_path
  }.freeze

  ICONS = {
    play: '<path d="M8 5.14v13.72a1 1 0 0 0 1.5.86l11.04-6.86a1 1 0 0 0 0-1.72L9.5 4.28A1 1 0 0 0 8 5.14z" fill="currentColor" stroke="none"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    bolt: '<path d="M13 2 4 14h7l-1 8 9-12h-7l1-8z"/>',
    calendar: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/>',
    dumbbell: '<path d="M6 7v10M18 7v10M3 9v6M21 9v6M6 12h12"/>',
    heart: '<path d="M12 20.5s-7.5-4.6-9.3-9.2C1.5 8.2 3.4 5 6.6 5c2 0 3.4 1.1 4.2 2.4h2.4C14 6.1 15.4 5 17.4 5c3.2 0 5.1 3.2 3.9 6.3-1.8 4.6-9.3 9.2-9.3 9.2z"/>',
    lock: '<rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>',
    arrow: '<path d="M5 12h14M13 6l6 6-6 6"/>'
  }.freeze

  def site_icon(name, css = "siteIcon")
    %(<svg class="#{css}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">#{ICONS.fetch(name)}</svg>).html_safe
  end

  # Imagen de un workout que llena su contenedor. Las miniaturas hqdefault y
  # sddefault de YouTube son 4:3 con barras negras arriba y abajo; con
  # is-letterboxed la imagen se dibuja 33% más alta que el contenedor, así
  # las barras quedan siempre fuera sin importar la proporción (tarjeta,
  # banner o portada vertical en celular).
  #
  # La imagen se sirve desde la app (WorkoutThumbnailsController), nunca desde
  # i.ytimg.com: esa URL trae el ID del video.
  def workout_media(workout, size: :cover, css: nil, lazy: true)
    url = size == :card ? workout.card_image_url : workout.cover_url
    letterboxed = url.to_s.match?(%r{/(hq|sd)default\.jpg\z})
    content_tag(:div, class: [ "wMedia", css, ("is-letterboxed" if letterboxed) ].compact.join(" ")) do
      if url
        src = workout_thumbnail_path(workout, size: size, v: Digest::MD5.hexdigest(url).first(8))
        image_tag(src, alt: "", loading: (lazy ? "lazy" : nil), decoding: "async", onerror: "this.remove()")
      end
    end
  end

  # Grupo · duración · intensidad, para etiquetas y líneas de detalle.
  def workout_facts(workout)
    [ workout.category_name, workout.duration_label, (workout.intensity_name && "Intensidad #{workout.intensity_name.downcase}") ].compact
  end

  def workout_category_path(category)
    route = CATEGORY_PATHS[category]
    route && public_send(route)
  end

  # IDs de los workouts en favoritas de la sesión (una consulta por página).
  def favorite_workout_ids
    @favorite_workout_ids ||= current_user ? current_user.favorites.where(favorited_type: "Workout").pluck(:favorited_id).to_set : Set.new
  end

  def comment_initials(comment)
    comment.author_name.split(/[\s@._-]+/).reject(&:blank?).first(2).map { |part| part[0] }.join.upcase
  end
end
