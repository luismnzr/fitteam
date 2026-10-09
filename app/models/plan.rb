# Planes que se venden en /payments/new. El checkout solo acepta estos
# precios de Stripe (antes tomaba cualquier price_id que llegara en el form).
class Plan
  ALL = {
    "mensual" => "price_1IzXpjCQy9Hvq1vmGc0LWqMD",
    "trimestral" => "plan_KqlGFwlFG9zwrT",
    "semestral" => "plan_KqlUEfvr2JArdI",
    "anual" => "plan_L55kFu5JdL8uc4"
  }.freeze

  def self.price_id(key)
    ALL[key.to_s]
  end
end
