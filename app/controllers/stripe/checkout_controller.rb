class Stripe::CheckoutController < ApplicationController
    def pricing
        # lookup_keys_normal = %w[funcional]
        # lookup_keys_plus = %w[alimentacion]
        # @pricesNormal = Stripe::Price.list(lookup_keys: lookup_keys_normal, active: true, expand: ['data.product']).data.sort_by(&:unit_amount)
        # @pricesPlus = Stripe::Price.list(lookup_keys: lookup_keys_plus, active: true, expand: ['data.product']).data.sort_by(&:unit_amount)
    end

    def checkout    
        session = Stripe::Checkout::Session.create({
        customer: current_user.stripe_customer_id,
        mode: 'subscription',
        allow_promotion_codes: true,
        line_items: [{
            quantity: 1,
            price: params[:price_id]
        }],
        success_url: stripe_checkout_success_url,
        cancel_url: stripe_checkout_cancel_url,
        })
    redirect_to session.url, allow_other_host: true
        
    end

    def success
        flash[:notice] = "success"
        redirect_to root_url
    end
        
    def cancel
        flash[:alert] = "El pago falló"
        redirect_to payments_new_path
    end
end