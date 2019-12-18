class Backend::Box::SubscriptionsController < Backend::BackendController

  # after_action :verify_authorized
  before_filter :load_box

  has_scope :by_dietary_concerns, type: :array
  has_scope :states,              type: :array
  has_scope :new_subscribers,     type: :boolean
  has_scope :limit_to
  has_scope :by_coupons,          type: :array
  has_scope :by_plans,            type: :array

  has_scope :txn_after, using: [:date], type: :hash do |controller, scope, value|
    if value[0].present?
      date = Date.parse(value[0])
      scope.txn_after(date)
    else
      scope
    end
  end

  has_scope :started_between, using: [:from_date, :to_date], type: :hash do |controller, scope, value|
    if value[0].present? || value[1].present?
      from_date = value[0].present? ? Date.parse(value[0]) : nil
      to_date = value[1].present? ? Date.parse(value[1]) : nil
      scope.started_between(from_date, to_date)
    else
      scope
    end
  end

  def index
    if params[:query].present?
      @box_orders = apply_scopes(policy_scope(@box.box_orders)).includes([box_subscription: :user]).where(box_subscription_id: @box.box_subscriptions.search_for_subscription(params[:query])).page(params[:page]).per(params[:per_page] || 15)
    else
      @box_orders = apply_scopes(policy_scope(@box.box_orders)).includes([box_subscription: :user]).page(params[:page]).per(params[:per_page] || 15)
    end

    authorize @box_orders
  end

  def search
    @submit_bulk_add = params[:commit] == 'Bulk Add'
    if params[:query].present?
      @all_subscriptions = apply_scopes(policy_scope(BoxSubscription.assignable(@box.date))).search_for_subscription(params[:query])
      @subscriptions = @all_subscriptions.page(params[:page]).per(params[:per_page] || 15)
    else
      @all_subscriptions = apply_scopes(policy_scope(BoxSubscription.assignable(@box.date)))
      @subscriptions = @all_subscriptions.page(params[:page]).per(params[:per_page] || 15)
    end

    if @submit_bulk_add
      bulk_add_subscriptions(@all_subscriptions)
      load_box_orders
    end

    authorize @subscriptions
  end

  def create
    @subscription = BoxSubscription.find params[:subscription_id]
    @error = BoxAllocator::Allocator.new(@subscription, box: @box, date: @box.date).allocate
    load_box_orders
    @box.reload
  end

  def destroy
    @box_order = @box.box_orders.find params[:id]
    authorize @box_order
    @box_order.destroy
  end

  private

    def load_box
      @box = ::Box.includes([:box_subscriptions]).find params[:box_id]
      # authorize @box
    end

    def load_box_orders
      @box_orders = @box.box_orders.includes([box_subscription: :user]).page(params[:page]).per(params[:per_page] || 15)
    end

    def bulk_add_subscriptions subscriptions
      subscriptions.each do |subscription|
        BoxAllocator::Allocator.new(subscription, box: @box, date: @box.date).allocate
      end
    end

end
