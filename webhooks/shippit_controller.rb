class Webhooks::ShippitController < ApplicationController

  skip_before_filter :verify_authenticity_token
  before_action :authenticate_shippit, only: [:webhook]

  def webhook
    begin
      ::ShippitWebhookHandler.new(params).perform
      render json: { status: 'Webhook success' }, :status => 200
    rescue => e
      Raven.capture_exception(e)
      render json: { error: e.message }, :status => 400
    end
  end

  private

  def authenticate_shippit
    if Rails.env.staging? or Rails.env.production?
      params[:auth] == ENV["SHIPPIT_WEBHOOK_AUTH"]
    end
  end

end
