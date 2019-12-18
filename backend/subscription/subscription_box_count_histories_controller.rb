class Backend::Subscription::SubscriptionBoxCountHistoriesController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_subscription

  def index
    @box_subscription_box_histories = @box_subscription.subscription_box_count_histories.order(created_at: :desc).page(params[:page]).per(params[:per_page])
  end

  def new
    @subscription_box_count_history = @box_subscription.subscription_box_count_histories.new
  end

  def create
    @subscription_box_count_history = @box_subscription.subscription_box_count_histories.new permitted_params.subscription_box_count_history
    @subscription_box_count_history.creator = current_user

    respond_to do |format|
      if @subscription_box_count_history.save
        format.json { render json:{ errors: nil, message: 'Succesfully saved box count adjustment' }, status: :ok }
      else
        format.json { render json:{ errors: @subscription_box_count_history.errors, message: 'Errors saving adjustment' }, status: :unprocessable_entity }
      end
    end
  end

  private

    def load_subscription
      @box_subscription = ::BoxSubscription.find params[:subscription_id]
      authorize @box_subscription
    end


end
