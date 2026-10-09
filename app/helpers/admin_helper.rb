# Helpers del admin (layout, navegación, fechas en español y badges).
# Rails incluye todos los helpers en todas las vistas, así que todo lleva el
# prefijo admin_ para no chocar con los del sitio público.
module AdminHelper
  ADMIN_TIME_ZONE = ApplicationHelper::TIME_ZONE
  MESES_LARGOS = %w[enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre].freeze
  DIAS = %w[Dom Lun Mar Mié Jue Vie Sáb].freeze

  # Estados de suscripción que reporta Stripe, en español.
  SUBSCRIPTION_STATUSES = {
    "active" => "Activa",
    "trialing" => "En prueba",
    "past_due" => "Pago pendiente",
    "unpaid" => "Sin pagar",
    "canceled" => "Cancelada",
    "incomplete" => "Incompleta",
    "incomplete_expired" => "Expirada",
    "paused" => "Pausada"
  }.freeze

  ICONS = {
    "dashboard" => '<path stroke-linecap="round" stroke-linejoin="round" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/>',
    "workouts" => '<path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>',
    "users" => '<path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/>',
    "comments" => '<path stroke-linecap="round" stroke-linejoin="round" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"/>',
    "calendar" => '<path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>',
    "external" => '<path stroke-linecap="round" stroke-linejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/>',
    "plus" => '<path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>',
    "search" => '<path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>',
    "check" => '<path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>',
    "heart" => '<path stroke-linecap="round" stroke-linejoin="round" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/>',
    "star" => '<path stroke-linecap="round" stroke-linejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.562.562 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.562.562 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z"/>',
    "user-plus" => '<path stroke-linecap="round" stroke-linejoin="round" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"/>',
    "credit-card" => '<path stroke-linecap="round" stroke-linejoin="round" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>',
    "menu" => '<path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"/>',
    "close" => '<path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>',
    "arrow-left" => '<path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>',
    "trash" => '<path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>',
    "reply" => '<path stroke-linecap="round" stroke-linejoin="round" d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6"/>',
    "link" => '<path stroke-linecap="round" stroke-linejoin="round" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"/>',
    "fire" => '<path stroke-linecap="round" stroke-linejoin="round" d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z"/><path stroke-linecap="round" stroke-linejoin="round" d="M9.879 16.121A3 3 0 1012.015 11L11 14H9c0 .768.293 1.536.879 2.121z"/>',
    "chevron-left" => '<path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/>',
    "chevron-right" => '<path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7"/>'
  }.freeze

  def admin_icon(name, css = "h-4 w-4")
    paths = ICONS.fetch(name.to_s)
    %(<svg class="#{css}" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">#{paths}</svg>).html_safe
  end

  # Link de la sidebar. Una sección queda activa también en sus subpáginas
  # (/admin/workouts/12/edit marca "Workouts"); el Panel solo en /admin.
  def admin_nav_link(label, path, icon)
    active = if path == admin_root_path
      request.path == path
    else
      request.path == path || request.path.start_with?("#{path}/")
    end
    link_to path, class: class_names("nav-link", "is-active" => active), "aria-current": (active ? "page" : nil) do
      admin_icon(icon) + content_tag(:span, label)
    end
  end

  def admin_time(time)
    time&.in_time_zone(ADMIN_TIME_ZONE)
  end

  def admin_today
    Date.current
  end

  def admin_date(time)
    short_date(time)
  end

  def admin_datetime(time)
    return "—" if time.blank?

    "#{admin_date(time)} · #{admin_time(time).strftime('%H:%M')}"
  end

  # "Lun 13 oct"
  def admin_day_label(date)
    "#{DIAS[date.wday]} #{date.day} #{ApplicationHelper::MESES[date.month - 1]}"
  end

  def admin_month_label(date)
    "#{MESES_LARGOS[date.month - 1].capitalize} #{date.year}"
  end

  # "hace 5 min", "hace 3 h", "hace 2 días"; más de una semana: la fecha.
  def admin_time_ago(time)
    return "—" if time.blank?

    seconds = (Time.current - time).to_i
    if seconds < 60
      "hace un momento"
    elsif seconds < 3600
      "hace #{seconds / 60} min"
    elsif seconds < 86_400
      "hace #{seconds / 3600} h"
    elsif seconds < 7 * 86_400
      days = seconds / 86_400
      days == 1 ? "ayer" : "hace #{days} días"
    else
      admin_date(time)
    end
  end

  def admin_initials(user)
    source = user.name.presence || user.email
    source.split(/[\s@._-]+/).reject(&:blank?).first(2).map { |part| part[0] }.join.upcase
  end

  # El acceso al contenido lo decide subscription_ends_at (User#active?):
  # lo pone el webhook de Stripe o, para cortesías, el admin.
  def admin_access_badge(user)
    if user.active?
      content_tag(:span, "Con acceso", class: "badge badge-success", title: "Hasta el #{admin_date(user.subscription_ends_at)}")
    else
      content_tag(:span, "Sin acceso", class: "badge")
    end
  end

  def admin_subscription_status(user)
    status = user.subscription_status.presence
    return "—" unless status

    SUBSCRIPTION_STATUSES.fetch(status, status)
  end

  def admin_stripe_customer_url(user)
    return if user.stripe_customer_id.blank?

    "https://dashboard.stripe.com/customers/#{user.stripe_customer_id}"
  end

  def admin_stripe_subscription_url(user)
    return if user.subscription_id.blank?

    "https://dashboard.stripe.com/subscriptions/#{user.subscription_id}"
  end

  # Los selects viejos guardaban "-" como "sin valor".
  def admin_value(value, empty = "—")
    value.blank? || value == "-" ? empty : value
  end

  def admin_error_messages(record)
    return if record.errors.none?

    content_tag(:div, class: "alert-error") do
      content_tag(:p, "No se pudo guardar:", class: "font-medium mb-1") +
        content_tag(:ul, class: "list-disc pl-5 space-y-0.5") do
          safe_join(record.errors.full_messages.map { |message| content_tag(:li, message) })
        end
    end
  end

  # Miniatura de un workout: la imagen de su video en YouTube.
  def admin_workout_thumb(workout, css: "h-12 w-20")
    url = workout_cover_url(workout)
    content_tag(:div, class: "thumb #{css}") do
      image_tag(url, alt: "", loading: "lazy") if url
    end
  end
end
