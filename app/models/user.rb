class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  after_create :create_stripe_customer

  def create_stripe_customer
     stripe_customer = Stripe::Customer.create(email: email)
  end

  def active?
    return false unless subscription_ends_at.present?
    subscription_ends_at > Time.zone.now
  end

  def admin?
    admin == true
  end

  # Devise emails (reset de contraseña, etc.) se envían en segundo plano:
  # si el servidor SMTP rechaza el envío, el error queda en el log en vez
  # de romper el request del usuario con una pantalla de error.
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  # Only require password if it's a new record or the password is explicitly set
  validates :password, presence: true, if: -> { new_record? || password.present? }

  has_many :comments

  has_many :favorites
  has_many :favorite_workouts, through: :favorites, source: :favorited, source_type: 'Workout'
end