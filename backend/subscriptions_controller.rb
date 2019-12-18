class Backend::SubscriptionsController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_box_subscription, only: [:show, :edit, :update, :destroy, :review]

  def index
    if params[:query].present?
      @box_subscriptions = apply_scopes(policy_scope(BoxSubscription.all)).search_for_subscription(params[:query]).page(params[:page]).per(params[:per_page] || 15)
    else
      @box_subscriptions = apply_scopes(policy_scope(BoxSubscription.all)).page(params[:page]).per(params[:per_page] || 15)
    end
    authorize @box_subscriptions
  end

  def show
    @subscription_box_count_histories = @box_subscription.subscription_box_count_histories
    @transactions = ChargeBee::Transaction.transactions_for_subscription(@box_subscription.chargebee_id, :limit => 10) if @box_subscription.chargebee_id.present?
  end

  def edit
    @customer = @box_subscription.user
    @billing_addresses = @customer.addresses.billing
    @shipping_addresses = @customer.addresses.shipping
  end

  # def destroy
    # @box_subscription.destroy
    # redirect_to backend_subscriptions_path, notice: 'Subscription Removed'
  # end

  private

    def load_box_subscription
      @box_subscription = BoxSubscription.find params[:id]
      authorize @box_subscription
    end
end
