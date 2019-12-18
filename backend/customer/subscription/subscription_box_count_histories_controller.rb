class Backend::Customer::Subscription::SubscriptionBoxCountHistoriesController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_subscription
  before_filter :load_customer

  def new
    @subscription_box_count_history = @box_subscription.subscription_box_count_histories.new
  end

  def edit
    load_subscription_box_count_history
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

  def update
    load_subscription_box_count_history
    @subscription_box_count_history.assign_attributes permitted_params.subscription_box_count_history

    if @subscription_box_count_history.save
      redirect_to edit_backend_customer_subscription_subscription_box_count_history_path(@customer, @box_subscription, @subscription_box_count_history), notice: 'Box Count history was successfully updated.'
    else
      render :edit, alert: 'Box Count History was not updated.'
    end
  end

  private

    def load_subscription_box_count_history
      @subscription_box_count_history = ::SubscriptionBoxCountHistory.find(params[:id])
      authorize @subscription_box_count_history
    end

    def load_subscription
      @box_subscription = ::BoxSubscription.find params[:subscription_id]
      authorize @box_subscription
    end

    def load_customer
      @customer = User.customers.find params[:customer_id]
      authorize @customer
    end

end
