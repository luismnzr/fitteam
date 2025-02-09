class PaymentsController < ApplicationController
     before_action :authenticate_user!

     def new
     end

     def create
       plan = SubscriptionPlan::PLANS[params[:plan].to_sym]

       session = Stripe::Checkout::Session.create(
         payment_method_types: ['card'],
         line_items: [{
           price: plan[:stripe_price_id],
           quantity: 1
         }],
         mode: 'subscription',
         success_url: payments_success_url + "?session_id={CHECKOUT_SESSION_ID}",
         cancel_url: payments_cancel_url
       )

       redirect_to session.url, allow_other_host: true
     end

     def success
       session = Stripe::Checkout::Session.retrieve(params[:session_id])
       subscription = session.subscription

       current_user.create_subscription(
         stripe_subscription_id: subscription,
         plan: session.metadata.plan,
         status: 'active'
       )

       redirect_to root_path, notice: 'Subscription successful!'
     end

     def cancel
       redirect_to root_path, alert: 'Subscription canceled.'
     end
   end