class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :comments, dependent: :nullify
  has_many :favorites, dependent: :destroy
  has_many :favorite_workouts, through: :favorites, source: :favorited, source_type: "Workout"

  # Con acceso al contenido: su suscripción (o el acceso de cortesía que se
  # da desde el admin) sigue vigente.
  scope :with_access, -> { where("users.subscription_ends_at > ?", Time.current) }
  scope :without_access, -> { where("users.subscription_ends_at IS NULL OR users.subscription_ends_at <= ?", Time.current) }

  after_create_commit :create_stripe_customer

  def active?
    subscription_ends_at.present? && subscription_ends_at.future?
  end

  # Las admins ven las clases aunque no tengan suscripción.
  def can_watch?
    admin? || active?
  end

  def display_name
    name.presence || email.split("@").first
  end

  # Cliente de Stripe para el checkout y el portal de pagos. Normalmente ya
  # existe desde el registro; si aquel intento falló, se crea aquí.
  def ensure_stripe_customer!
    return stripe_customer_id if stripe_customer_id.present?

    customer = Stripe::Customer.create(email: email, name: name.presence)
    update_column(:stripe_customer_id, customer.id)
    customer.id
  end

  private

  # Un problema con Stripe no debe impedir el registro: el cliente se vuelve a
  # intentar al elegir un plan (ensure_stripe_customer!).
  def create_stripe_customer
    return if Stripe.api_key.blank?

    ensure_stripe_customer!
  rescue Stripe::StripeError => e
    Rails.logger.warn("[Stripe] No se pudo crear el cliente de #{email}: #{e.message}")
  end
end
