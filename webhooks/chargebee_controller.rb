class Webhooks::ChargebeeController < ApplicationController
  include ErrorSerializer

  skip_before_filter :verify_authenticity_token
  before_action :authenticate_chargebee, only: [:webhook]

  SUBSCRIPTION_EVENTS = %w(
                          subscription_changed
                          subscription_cancellation_scheduled
                          subscription_scheduled_cancellation_removed
                          subscription_created
                          subscription_started
                          subscription_activated
                          subscription_renewed
                          subscription_cancelled
                          subscription_trial_ending
                          subscription_reactivated
                          subscription_cancelling
    )

  PAYMENT_EVENTS = %w(payment_succeeded)

  def webhook
    begin
      handler = ChargebeeWebhookHandler.new(params)
      handler.user_found?

      if SUBSCRIPTION_EVENTS.include? params[:event_type]
        handler.perform_subscription_update
      end

      if PAYMENT_EVENTS.include? params[:event_type]
        handler.perform_payment_succeeded
      end
      render nothing: true
    rescue SubscriptionNotFoundError
      render json: ErrorSerializer.serialize(handler.errors), status: 500
    rescue UserNotFoundError
      render json: ErrorSerializer.serialize(handler.errors), status: 500
    rescue TransactionAlreadyProcessedError
      render json: ErrorSerializer.serialize(handler.errors), status: 500
    end

  end

  private

  def authenticate_chargebee
    if Rails.env.staging? or Rails.env.production?
      authenticate_or_request_with_http_basic do |username, password|
        username == ENV["CHARGEBEE_WEBHOOK_USERNAME"] && password == ENV["CHARGEBEE_WEBHOOK_PASSWORD"]
      end
    end
  end
end
