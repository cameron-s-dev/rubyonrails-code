class Backend::EventsController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_event, only: [:show, :edit, :update]

  def index
    if params[:query].present?
      @events = apply_scopes(policy_scope(::Event)).search_for_event(params[:query]).page(params[:page]).per(params[:per_page] || 15)
    else
    @events = apply_scopes(policy_scope(::Event)).page(params[:page]).per(params[:per_page] || 15)
    end
    authorize @events
  end

  def show

  end

  def new
    @event = Event.new
    authorize @event
  end

  def create
    @event = Event.new permitted_params.event
    authorize @event
    if @event.save
      redirect_to backend_events_url, notice: 'Event was successfully created.'
    else
      render :new, alert: 'Event was not created.'
    end
  end

  def update
    if @event.update_attributes permitted_params.event
      redirect_to backend_events_url, notice: 'Event was successfully updated.'
    else
      render :edit, alert: 'Event was not updated.'
    end
  end

  private

    def load_event
      @event = ::Event.find params[:id]
      authorize @event
    end

end
