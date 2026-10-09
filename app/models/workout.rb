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

  has_one_attached :cover
  has_many :comments, dependent: :destroy
  has_many :favorites, as: :favorited, dependent: :destroy

  validates :title, presence: true

  before_validation :normalize_video_url

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
    material.to_s.split(",").map(&:strip).reject(&:blank?)
  end

  # Acepta el ID de YouTube o cualquier link de YouTube.
  def youtube_id
    value = video_url.to_s.strip
    value[YOUTUBE_ID, 1] || value[/\A[\w-]{11}\z/]
  end

  # Miniatura del video (no requiere API). hqdefault existe para todos los
  # videos; en un recorte 16:9 sus barras negras quedan fuera.
  def youtube_thumbnail_url
    "https://i.ytimg.com/vi/#{youtube_id}/hqdefault.jpg" if youtube_id
  end

  private

  # Guarda solo el ID, que es lo que usa el reproductor del sitio.
  def normalize_video_url
    self.video_url = youtube_id || video_url.to_s.strip.presence
  end
end
