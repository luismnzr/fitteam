class AddAttributesToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :admin, :boolean
    add_column :users, :name, :string
    add_column :users, :stripe_customer_id, :string
    add_column :users, :subscription_status, :string
    add_column :users, :subscription_ends_at, :string
  end
end
