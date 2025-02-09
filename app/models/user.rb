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
end