module ApplicationHelper
  TIME_ZONE = Rails.application.config.time_zone
  MESES = %w[ene feb mar abr may jun jul ago sep oct nov dic].freeze

  # "9 oct 2026" (la app corre en locale :en, así que no usamos l()).
  def short_date(value)
    return "—" if value.blank?

    value = value.in_time_zone(TIME_ZONE) if value.respond_to?(:in_time_zone) && !value.is_a?(Date)
    "#{value.day} #{MESES[value.month - 1]} #{value.year}"
  end

  # Liga del header; marca la página en la que estás.
  def site_nav_link(label, path)
    current = current_page?(path)
    link_to label, path, class: class_names("siteHeader-link", "is-active" => current), "aria-current": (current ? "page" : nil)
  end
end
