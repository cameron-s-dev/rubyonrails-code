class Backend::Customer::SubscriptionsController < Backend::BackendController
  include SubscriptionHostedPages

  after_action :verify_authorized
  before_filter :load_customer
  before_filter :load_subscription, only: [:show, :edit, :update]
  before_filter :load_required_box_subscription_info, only: [:show, :edit, :update]

  decorates_assigned :box_subscriptions, :box_subscription

  def index
    @box_subscriptions = @customer.box_subscriptions.page(params[:page]).per(params[:per_page])
    authorize @box_subscriptions
  end

  def new
    @subscription_form = CreateSubscription.new
    authorize @subscription_form.box_subscription
  end

  def create
    @subscription_form = CreateSubscription.new(permitted_params.create_subscription.merge(customer: @customer, current_user: current_user))
    authorize @subscription_form.box_subscription
    if @subscription_form.save
      redirect_to backend_customer_subscriptions_path(@customer), notice: 'Subscription was successfully created.'
    else
      render :new, alert: 'Subscription was not created.'
    end
  end

  def show
    @errors = []
    @subscription_box_count_histories = @box_subscription.subscription_box_count_histories
    begin
    @transactions = ChargeBee::Transaction.transactions_for_subscription(@box_subscription.chargebee_id, :limit => 10) if @box_subscription.chargebee_id.present?
    rescue ChargeBee::InvalidRequestError
      @errors << "Subscription with <strong>#{@box_subscription.chargebee_id}</strong> not found in Chargebee"
    end
  end

  def payment_details
  end

  def health_profile
  end

  def edit
    load_subscription
  end

  def update
    load_subscription
    @box_subscription.assign_attributes permitted_params.box_subscription

    if @box_subscription.save
      redirect_to edit_backend_customer_subscription_url(@customer, @box_subscription), notice: 'Box subscription was successfully updated.'
    else
      render :edit, alert: 'Box subscription was not updated.'
    end
  end

  def sync_with_chargebee
    load_subscription
    @box_subscription.sync_chargebee_subscription
    redirect_to :back, notice: "Subscription details updated from Chargebee data"
  end

  def send_gift_email
    @box_subscription = BoxSubscription.find params[:box_subscription_id]
    if !SubscriptionMailer.send_gift_recipient_message(@box_subscription.id).deliver_now
      redirect_to backend_customer_subscription_path(
        @customer, @box_subscription), notice: 'Gift email was successfully re-sent.'
    else
      redirect_to backend_customer_subscription_path(
        @customer, @box_subscription), alert: 'Gift email was unable to be resent'
    end

  end

  private

  def selected_user
    @customer
  end

  def load_customer
    @customer = User.customers.find params[:customer_id]
    authorize @customer
  end

  def load_subscription
    @box_subscription = @customer.box_subscriptions.find(params[:id] || params[:subscription_id])
    authorize @box_subscription
  end

  def load_required_box_subscription_info
    # @chargebee_customer = @customer.chargebee_customer # doesn't seem to be used anywhere
    @billing_addresses = @customer.addresses.billing
    @shipping_addresses = @customer.addresses.shipping
  end

end
