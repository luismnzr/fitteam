# Compara el acceso de cada usuaria con su suscripción en Stripe (StripeSync).
#
#   heroku run rails stripe:report   # muestra las diferencias, no cambia nada
#   heroku run rails stripe:sync     # las corrige
#
# stripe:sync no quita el acceso a muchas de golpe (más de 5 y más del 30%
# de las que tienen acceso) sin FORCE=1: revisa antes con stripe:report.
#
# stripe:sync también puede correr cada día en Heroku Scheduler, por si algún
# webhook no llegó.
namespace :stripe do
  desc "Muestra en qué no coincide el acceso de las usuarias con Stripe (no cambia nada)"
  task report: :environment do
    StripeSync.run(dry_run: true)
  rescue StripeSync::Error => e
    abort e.message
  end

  desc "Deja el acceso de todas las usuarias igual a su suscripción en Stripe"
  task sync: :environment do
    StripeSync.run(dry_run: false, force: ENV["FORCE"].present?)
  rescue StripeSync::Error => e
    abort e.message
  end
end
