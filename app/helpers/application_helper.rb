module ApplicationHelper
  TIME_ZONE = Rails.application.config.time_zone
  MESES = %w[ene feb mar abr may jun jul ago sep oct nov dic].freeze

  # "9 oct 2026" (la app corre en locale :en, así que no usamos l()).
  def short_date(value)
    return "—" if value.blank?

    value = value.in_time_zone(TIME_ZONE) if value.respond_to?(:in_time_zone) && !value.is_a?(Date)
    "#{value.day} #{MESES[value.month - 1]} #{value.year}"
  end
end
