ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

# Respuestas falsas de la API de Stripe para StripeSync.
module StripeStubs
  def stripe_subscription(id:, customer:, status: "active", ends_at: 30.days.from_now, created: Time.current, email: nil)
    customer = { id: customer, object: "customer", email: email } if email
    Stripe::Subscription.construct_from(
      id: id, object: "subscription", customer: customer, status: status,
      current_period_end: ends_at.to_i, created: created.to_i
    )
  end

  def stripe_list(items)
    Stripe::ListObject.construct_from(object: "list", data: [], has_more: false).tap { |list| list.data = items }
  end

  # Stripe::Subscription.list devuelve las suscripciones dadas, filtradas
  # por cliente si así se pide. Las llamadas quedan en el arreglo que se pasa.
  def with_stripe_subscriptions(subscriptions, customers: [], calls: [], &block)
    customer_id = ->(subscription) { subscription.customer.is_a?(String) ? subscription.customer : subscription.customer.id }
    list = lambda do |params = {}, _opts = {}|
      calls << params
      stripe_list(params[:customer] ? subscriptions.select { |s| customer_id.call(s) == params[:customer] } : subscriptions)
    end
    customer_list = ->(params = {}, _opts = {}) { stripe_list(customers.select { |c| c[:email] == params[:email] }) }
    retrieve = ->(id, _opts = {}) { customers.find { |c| c.id == id } || Stripe::Customer.construct_from(id: id, object: "customer") }

    Stripe::Subscription.stub(:list, list) do
      Stripe::Customer.stub(:list, customer_list) do
        Stripe::Customer.stub(:retrieve, retrieve, &block)
      end
    end
  end

  def stripe_customer(id, email)
    Stripe::Customer.construct_from(id: id, object: "customer", email: email)
  end
end

class ActiveSupport::TestCase
  include StripeStubs
end
