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

  has_many :comments

  has_many :favorites
  has_many :favorite_workouts, through: :favorites, source: :favorited, source_type: 'Workout'
end