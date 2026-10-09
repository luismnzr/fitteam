# subscription_ends_at era string: el acceso se decidía comparando texto con
# una fecha. Pasa a datetime para poder filtrar y ordenar en SQL (admin).
# Los valores que no empiezan con una fecha (AAAA-MM-DD) quedan en NULL.
class ChangeSubscriptionEndsAtToDatetime < ActiveRecord::Migration[7.2]
  def up
    change_column :users, :subscription_ends_at, :datetime,
                  using: "CASE WHEN subscription_ends_at ~ '^\\d{4}-\\d{2}-\\d{2}' THEN subscription_ends_at::timestamptz END"
  end

  def down
    change_column :users, :subscription_ends_at, :string
  end
end
