# Suscripción de Stripe que da el acceso. El webhook la usa para que la
# cancelación de una suscripción vieja no le quite el acceso a la actual.
class AddSubscriptionIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :subscription_id, :string
    add_index :users, :stripe_customer_id
  end
end
