class Backend::BoxesController < Backend::BackendController

  after_action :verify_authorized, except: [:allocate_box_orders]
  before_filter :load_box, only: [:show, :edit, :update, :destroy, :review, :finalise, :dispatcher, :process_orders, :edit_threshold, :threshold, :redraft]

  # box orders scopes for dispatcher
  has_scope :states,              type: :array
  has_scope :tracking_states,     type: :array

  def index
    if params[:query].present?
      @boxes = apply_scopes(policy_scope(::Box)).search_for_box(params[:query]).order(:date).page(params[:page]).per(params[:per_page] || 100)
    else
      @boxes = apply_scopes(policy_scope(::Box)).page(params[:page]).order(:date).per(params[:per_page] || 100)
    end
    authorize @boxes
  end

  def edit
  end

  def new
    @box = ::Box.new(one_off: params[:one_off])
    authorize @box
  end

  def create
    @box = ::Box.new permitted_params.box
    authorize @box
    if @box.save
      redirect_to [:backend, @box], notice: 'Box was successfully created.'
    else
      render :new, alert: 'Box was not created.'
    end
  end

  def update
    if @box.update_attributes permitted_params.box
      redirect_to [:backend, @box], notice: 'Box was successfully updated.'
    else
      render :edit, alert: 'Box was not updated.'
    end
  end

  def review
    load_review
  end

  def finalise
    @box.assign_attributes permitted_params.box
    if @box.finalise
      redirect_to dispatcher_backend_box_path(@box), notice: 'Box is finalised and ready to send.'
    else
      load_review
      render :review, alert: 'Box was not finalised.'
    end
  end

  def redraft
    if @box.redraft
      redirect_to backend_box_path(@box), notice: 'Box has been unpublished.'
    else
      redirect_to backend_box_path(@box), alert: 'Box was not unpublished.'
    end
  end

  def allocate_box_orders
    @selected_date = Date.parse(params.fetch(:date, Date.today.to_s))
    @subscriptions = BoxSubscription.not_allocated(@selected_date)
    BoxAllocator::Allocator.allocate_all(@subscriptions, @selected_date)
    redirect_to backend_root_path, notice: "Jobs queued"
  end

  def dispatcher
    @review = BoxHandler::Review.new(@box)
    @batches = @box.batch_sorter.batches
    @queue  = Sidekiq.redis { |r| r.lrange "queue:box_orders_dispatcher", 0, -1 }
    load_box_orders
  end

  def process_orders
    @box_handler = BoxHandler::Dispatcher.new(@box)
    @box_handler.process_orders_for_batch(params[:batch_id])
    redirect_to dispatcher_backend_box_path(@box), notice: 'Batch orders sent to Shippit'
  end

  def destroy
    @box.destroy
    redirect_to backend_boxes_path, notice: 'Box Removed'
  end

  def edit_threshold
    @box
  end

  def threshold
    @box.update_attributes permitted_params.box
  end

private

  def load_box_orders
    if params[:query].present?
      @box_orders = apply_scopes(@box.box_orders.includes(:user, :box_subscription)).search(params[:query]).page(params[:page]).per(params[:per_page] || 10)
    else
      @box_orders = apply_scopes(@box.box_orders.includes(:user, :box_subscription)).page(params[:page]).per(params[:per_page] || 10)
    end
  end

  def load_box
    @box = ::Box.includes([:products]).find(params[:id]).decorate
    authorize @box
  end

  def load_review
    @review = BoxHandler::Review.new(@box)
  end

end
