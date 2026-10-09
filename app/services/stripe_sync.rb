# Deja el acceso de cada usuaria igual a lo que dice Stripe.
#
# Para quien paga, Stripe manda: el acceso dura hasta el fin del periodo de
# su suscripción con acceso (active, trialing o past_due; si tiene más de
# una, la que termina más tarde). Si no tiene ninguna con acceso:
# - si el acceso que tiene salió de Stripe (la suscripción guardada, o una
#   fecha que coincide con el fin de periodo de alguna de sus suscripciones,
#   como las que guardaba el webhook anterior), se le quita;
# - si no, es una cortesía del admin y no se toca.
#
# Lo usan el webhook (con cada evento se vuelven a leer de Stripe todas las
# suscripciones de la clienta, así no importa el orden en que lleguen los
# eventos ni si tiene más de una), el regreso del checkout, el botón
# "Sincronizar con Stripe" del admin y `rails stripe:sync` (todas a la vez).
class StripeSync
  # past_due conserva el acceso mientras Stripe reintenta el cobro.
  ACCESS_STATUSES = %w[active trialing past_due].freeze

  # Margen para reconocer una fecha de acceso que vino de Stripe.
  SAME_PERIOD = 36.hours

  # stripe:sync no quita el acceso a más de este número y proporción de las
  # usuarias con acceso sin FORCE=1.
  MAX_REVOKED = 5
  MAX_REVOKED_SHARE = 0.3

  # Qué le pasó a una usuaria. kind: :granted, :revoked, :extended,
  # :shortened, :courtesy (tiene acceso sin suscripción en Stripe y no se
  # toca), :updated (solo el estado guardado), :unchanged o :not_found.
  Result = Struct.new(:user, :kind, :ends_at_before, :ends_at_after, :customer_before, :customer_after, :subscription, keyword_init: true) do
    def relinked?
      customer_before.present? && customer_before != customer_after
    end
  end

  # Resultado de sincronizar a todas (rails stripe:report / stripe:sync).
  Report = Struct.new(:results, :orphans, :conflicts, :unlinked_with_access, :subscriptions, :customers, keyword_init: true) do
    def of(kind)
      results.select { |result| result.kind == kind }
    end

    def relinked
      results.select(&:relinked?)
    end

    def to_text(dry_run:, mode:)
      out = [ "Stripe (#{mode}): #{subscriptions} suscripciones de #{customers} clientes." ]
      out << (dry_run ? "Simulación: no se cambió nada." : "Cambios aplicados.")
      section(out, "Ganan acceso", of(:granted)) { |r| "#{r.user.email}: sin acceso → hasta #{day(r.ends_at_after)} (#{plan(r.subscription)})" }
      section(out, "Pierden acceso", of(:revoked)) { |r| "#{r.user.email}: hasta #{day(r.ends_at_before)} → sin acceso (#{plan(r.subscription)})" }
      section(out, "Cambia la fecha de fin", of(:extended) + of(:shortened)) { |r| "#{r.user.email}: #{day(r.ends_at_before)} → #{day(r.ends_at_after)} (#{plan(r.subscription)})" }
      section(out, "Se ligan a otro cliente de Stripe", relinked) { |r| "#{r.user.email}: #{r.customer_before} → #{r.customer_after}" }
      section(out, "Con acceso y sin suscripción en Stripe (cortesía; no se tocan)", of(:courtesy).map(&:user) + unlinked_with_access) { |user| "#{user.email}: hasta #{day(user.subscription_ends_at)}" }
      section(out, "Pagan en Stripe y no tienen cuenta en la app", orphans) { |customer_id, email, subscription| "#{email.presence || "(sin correo)"} · #{customer_id} · #{plan(subscription)}" }
      section(out, "Pagan con dos clientes de Stripe (revisar a mano)", conflicts) { |user, current, other| "#{user.email}: #{current} y #{other}" }
      out << "" << "Solo cambia el estado guardado: #{of(:updated).size}. Sin cambios: #{of(:unchanged).size}."
      out << "Para aplicar los cambios: heroku run rails stripe:sync" if dry_run
      out.join("\n")
    end

    private

    def section(out, title, items, &line)
      return if items.empty?

      out << "" << "#{title} (#{items.size})"
      items.each { |item| out << "  #{item.is_a?(Array) ? line.call(*item) : line.call(item)}" }
    end

    def day(time)
      time ? time.in_time_zone.to_date.iso8601 : "—"
    end

    def plan(subscription)
      return "su suscripción ya no existe en Stripe" unless subscription

      ends_at = StripeSync.period_end(subscription)
      [ subscription.status, subscription.id, (ends_at && "periodo hasta #{day(ends_at)}") ].compact.join(", ")
    end
  end

  class Error < StandardError; end

  class << self
    # rails stripe:report (dry_run) y rails stripe:sync. Antes de aplicar,
    # simula: si le quitaría el acceso a muchas de golpe (una llave de otra
    # cuenta, por ejemplo), no cambia nada salvo con force.
    def run(dry_run:, force: false, io: $stdout)
      key = Stripe.api_key.to_s
      raise Error, "Falta STRIPE_SECRET_KEY." if key.blank?

      live = key.start_with?("sk_live", "rk_live")
      if !dry_run && Rails.env.production? && !live
        raise Error, "STRIPE_SECRET_KEY es de pruebas: en producción quitaría el acceso a quienes pagan. No se cambió nada."
      end

      report = sync_all(dry_run: true)
      unless dry_run
        revoked = report.of(:revoked).size
        if !force && revoked > MAX_REVOKED && revoked > User.with_access.count * MAX_REVOKED_SHARE
          raise Error, "Le quitaría el acceso a #{revoked} usuarias de una vez y no se cambió nada. " \
                       "Revisa la lista con rails stripe:report y, si es correcto, corre FORCE=1 rails stripe:sync."
        end
        report = sync_all
      end
      io.puts report.to_text(dry_run: dry_run, mode: live ? "live" : "test")
      report
    end

    # Una usuaria (botón del admin y regreso del checkout). Sin cliente de
    # Stripe guardado, busca el de su correo.
    def sync_user(user, dry_run: false)
      customer_id, subscriptions = customer_for(user)
      return Result.new(user: user, kind: :not_found) unless customer_id

      apply(user, customer_id, subscriptions, dry_run: dry_run)
    end

    # La dueña de un cliente de Stripe (webhook). Si ningún usuario lo tiene
    # guardado pero está pagando, se busca por el correo del cliente.
    def sync_customer(customer_id)
      subscriptions = subscriptions_for(customer_id)
      user = User.find_by(stripe_customer_id: customer_id) || owner_by_email(customer_id, subscriptions)
      return unless user

      apply(user, customer_id, subscriptions)
    end

    # Todas las clientas: una sola lectura de las suscripciones de Stripe.
    def sync_all(dry_run: false)
      by_customer = {}
      customers = {}
      Stripe::Subscription.list({ status: "all", limit: 100, expand: [ "data.customer" ] }).auto_paging_each do |subscription|
        customer = subscription.customer
        customer_id = customer.is_a?(String) ? customer : customer.id
        customers[customer_id] = customer unless customer.is_a?(String)
        (by_customer[customer_id] ||= []) << subscription
      end

      report = Report.new(results: [], orphans: [], conflicts: [], unlinked_with_access: [],
                          subscriptions: by_customer.values.sum(&:size), customers: by_customer.size)

      users = User.where.not(stripe_customer_id: [ nil, "" ]).to_a
      assignment = users.to_h { |user| [ user, user.stripe_customer_id ] }
      linked = users.map(&:stripe_customer_id).to_set

      # Clientes que pagan y que ningún usuario tiene guardados: por correo.
      by_customer.each do |customer_id, subscriptions|
        next if linked.include?(customer_id) || !grants?(subscriptions)

        email = customers[customer_id]&.[](:email)
        user = User.find_by(email: email.downcase) if email.present?
        current = user && assignment.find { |candidate, _| candidate.id == user.id }
        if user.nil?
          report.orphans << [ customer_id, email, best_subscription(subscriptions) ]
        elsif current && grants?(by_customer.fetch(current.last, []))
          report.conflicts << [ current.first, current.last, customer_id ]
        else
          assignment.delete(current.first) if current
          assignment[current&.first || user] = customer_id
        end
      end

      assignment.each do |user, customer_id|
        report.results << apply(user, customer_id, by_customer.fetch(customer_id, []), dry_run: dry_run)
      end

      report.unlinked_with_access = User.with_access.where(stripe_customer_id: [ nil, "" ])
                                        .where(admin: [ false, nil ])
                                        .where.not(id: assignment.keys.map(&:id)).order(:email).to_a
      report
    end

    def period_end(subscription)
      # Desde la API 2025-03-31 el fin del periodo vive en cada item de la
      # suscripción; en versiones anteriores, en la suscripción.
      timestamp = subscription[:current_period_end] ||
                  subscription[:items]&.[](:data)&.first&.[](:current_period_end)
      timestamp ? Time.zone.at(timestamp) : nil
    end

    def best_subscription(subscriptions)
      subscriptions.select { |subscription| ACCESS_STATUSES.include?(subscription.status) }
                   .max_by { |subscription| period_end(subscription) || Time.zone.at(0) }
    end

    private

    def apply(user, customer_id, subscriptions, dry_run: false)
      had_access = user.active?
      ends_at_before = user.subscription_ends_at
      customer_before = user.stripe_customer_id
      best = best_subscription(subscriptions)
      latest = subscriptions.max_by(&:created)

      attrs = { stripe_customer_id: customer_id }
      if best
        attrs[:subscription_id] = best.id
        attrs[:subscription_status] = best.status
        attrs[:subscription_ends_at] = period_end(best) || ends_at_before
      elsif latest
        revoke = had_access && from_stripe?(user, subscriptions)
        attrs[:subscription_id] = nil
        attrs[:subscription_status] = latest.status
        attrs[:subscription_ends_at] = [ ends_at_before, Time.current ].compact.min if revoke
      elsif had_access && user.subscription_id.present?
        # Su suscripción ya no existe en Stripe.
        attrs[:subscription_id] = nil
        attrs[:subscription_ends_at] = Time.current
      end

      user.assign_attributes(attrs)
      result = Result.new(
        user: user, kind: kind_for(user, had_access, ends_at_before, best),
        ends_at_before: ends_at_before, ends_at_after: user.subscription_ends_at,
        customer_before: customer_before, customer_after: customer_id,
        subscription: best || latest
      )

      if dry_run
        user.restore_attributes
      elsif user.changed?
        user.save!(validate: false)
      end
      result
    end

    def kind_for(user, had_access, ends_at_before, best)
      has_access = user.active?
      if !had_access && has_access then :granted
      elsif had_access && !has_access then :revoked
      elsif had_access && (user.subscription_ends_at.to_i - ends_at_before.to_i).abs > 60
        user.subscription_ends_at > ends_at_before ? :extended : :shortened
      elsif had_access && !best then :courtesy
      elsif user.changed? then :updated
      else :unchanged
      end
    end

    # ¿El acceso que tiene se lo dio Stripe? La suscripción guardada, o una
    # fecha igual al fin de periodo de alguna de sus suscripciones.
    def from_stripe?(user, subscriptions)
      return true if user.subscription_id.present?

      subscriptions.any? do |subscription|
        ends_at = period_end(subscription)
        ends_at && (ends_at - user.subscription_ends_at).abs <= SAME_PERIOD
      end
    end

    def grants?(subscriptions)
      best_subscription(subscriptions).present?
    end

    def subscriptions_for(customer_id)
      Stripe::Subscription.list({ customer: customer_id, status: "all", limit: 100 }).auto_paging_each.to_a
    end

    def customer_for(user)
      return [ user.stripe_customer_id, subscriptions_for(user.stripe_customer_id) ] if user.stripe_customer_id.present?

      candidates = Stripe::Customer.list({ email: user.email, limit: 10 }).data.map do |customer|
        [ customer.id, subscriptions_for(customer.id) ]
      end
      candidates.max_by { |_, subscriptions| [ grants?(subscriptions) ? 1 : 0, subscriptions.size ] }
    end

    # Cliente que paga y que ningún usuario tiene guardado (por ejemplo, uno
    # duplicado de antes): se liga a la usuaria de su correo, salvo que esa
    # usuaria ya pague con otro cliente.
    def owner_by_email(customer_id, subscriptions)
      return unless grants?(subscriptions)

      email = Stripe::Customer.retrieve(customer_id)[:email]
      user = User.find_by(email: email.downcase) if email.present?
      return unless user
      return user if user.stripe_customer_id.blank?

      user unless grants?(subscriptions_for(user.stripe_customer_id))
    end
  end
end
