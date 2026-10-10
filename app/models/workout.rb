class Workout < ApplicationRecord
  CATEGORIES = [ "Lower Body", "Upper Body", "ABS and Core", "Glutes and Hips", "Full Body" ].freeze
  DURATIONS = [ "15min", "30min", "45min", "1 hora" ].freeze
  INTENSITIES = [ "Baja", "Media", "Alta" ].freeze
  MATERIALS = [ "Banco", "Band", "Bicicleta Estatica", "Mancuernas Ligeras", "Mancuernas Medianas",
               "Mancuernas Pesadas", "Pelota", "Polainas", "Silla", "Sin Material", "Sliders",
               "Tapete", "Tubo" ].freeze
  # El color pinta el evento en el calendario público; el negro marca un estreno.
  NORMAL_COLOR = "#004a37".freeze
  PREMIERE_COLOR = "#111111".freeze

  YOUTUBE_ID = %r{(?:youtu\.be/|youtube(?:-nocookie)?\.com/(?:watch\?(?:.*&)?v=|embed/|shorts/|live/|v/))([\w-]{11})}

  has_many :comments, dependent: :destroy
  has_many :favorites, as: :favorited, dependent: :destroy

  validates :title, presence: true
  validate :video_url_is_youtube, if: :video_url_changed?

  before_validation :normalize_video_url
  # Otro video, otra miniatura (el admin la vuelve a pedir al guardar).
  before_save { self.thumbnail_url = nil if video_url_changed? }

  scope :premieres, -> { where(color: PREMIERE_COLOR) }

  # Opciones de un select con los valores fijos más los que ya existan en la
  # base (para no perder un valor viejo al editar).
  def self.options_for(values, column)
    (values + distinct.where.not(column => [ nil, "", "-" ]).pluck(column)).uniq
  end

  def premiere?
    color == PREMIERE_COLOR
  end

  def materials
    material.to_s.split(",").map(&:strip).reject { |m| m.blank? || m == "Sin Material" }
  end

  # "-" era el "sin valor" de los selects viejos.
  def category_name
    category unless category.blank? || category == "-"
  end

  def intensity_name
    intensity unless intensity.blank? || intensity == "-"
  end

  # "15min" -> "15 min"; "1 hora" se queda igual.
  def duration_label
    return if duration.blank? || duration == "-"

    duration.sub(/\A(\d+)\s*min\z/, '\1 min')
  end

  # Acepta el ID de YouTube o cualquier link de YouTube.
  def youtube_id
    value = video_url.to_s.strip
    value[YOUTUBE_ID, 1] || value[/\A[\w-]{11}\z/]
  end

  # Portada (tarjetas, banners y página del workout): la mejor miniatura de
  # YouTube que se encontró (thumbnail_url, la llena YoutubeThumbnail) o,
  # mientras tanto, hqdefault, que existe para todos los videos.
  # WorkoutThumbnailsController la recorta y la reduce para cada tamaño.
  def cover_url
    thumbnail_url.presence || youtube_thumbnail_url
  end

  # Busca y guarda la mejor miniatura si todavía no la tiene.
  def ensure_thumbnail_url!
    return thumbnail_url if thumbnail_url.present? || youtube_id.blank?

    url = YoutubeThumbnail.fetch(youtube_id)
    update_column(:thumbnail_url, url) if url
    url
  end

  # Miniaturas chicas del admin: mqdefault (320px, 16:9, sin barras).
  def small_thumbnail_url
    youtube_id ? youtube_thumbnail_url("mqdefault") : thumbnail_url.presence
  end

  def youtube_thumbnail_url(size = "hqdefault")
    "https://i.ytimg.com/vi/#{youtube_id}/#{size}.jpg" if youtube_id
  end

  private

  def video_url_is_youtube
    return if video_url.blank? || youtube_id

    errors.add(:video_url, "no es un link de YouTube válido")
  end

  # Guarda solo el ID, que es lo que usa el reproductor del sitio.
  def normalize_video_url
    self.video_url = youtube_id || video_url.to_s.strip.presence
  end
end
