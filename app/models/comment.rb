class Comment < ApplicationRecord
  belongs_to :workout
  # Opcional: los comentarios anteriores a 2026 no guardaban autor.
  belongs_to :user, optional: true
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent

  validates :text, presence: true

  # Comentarios de las usuarias (las respuestas de Ana Gaby llevan parent_id).
  scope :roots, -> { where(parent_id: nil) }
  scope :unanswered, -> { roots.where.not(id: Comment.unscoped.where.not(parent_id: nil).select(:parent_id)) }

  def author_name
    user&.display_name || "Miembro de Fitteam"
  end
end
