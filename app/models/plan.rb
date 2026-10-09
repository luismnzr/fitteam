# Planes que se venden (página de planes y home). El checkout solo acepta
# estos precios de Stripe (antes tomaba cualquier price_id que llegara en el
# form). El precio que se muestra es solo texto: el cobro real lo define el
# precio en Stripe, así que si cambia allá hay que cambiarlo aquí también.
class Plan
  Item = Struct.new(:key, :name, :price, :price_id, keyword_init: true)

  ALL = [
    Item.new(key: "mensual", name: "Plan Mensual", price: "499 mxn / mes", price_id: "price_1IzXpjCQy9Hvq1vmGc0LWqMD"),
    Item.new(key: "trimestral", name: "Plan Trimestral", price: "1300 mxn / trimestre", price_id: "plan_KqlGFwlFG9zwrT"),
    Item.new(key: "semestral", name: "Plan Semestral", price: "2300 mxn / semestre", price_id: "plan_KqlUEfvr2JArdI"),
    Item.new(key: "anual", name: "Plan Anual", price: "4400 mxn / año", price_id: "plan_L55kFu5JdL8uc4")
  ].freeze

  def self.all
    ALL
  end

  def self.price_id(key)
    ALL.find { |plan| plan.key == key.to_s }&.price_id
  end
end
