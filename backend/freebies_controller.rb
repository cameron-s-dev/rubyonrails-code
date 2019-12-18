class Backend::FreebiesController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_freeby, only: [:show, :edit, :update]

  def index
    if params[:query].present?
      @freebies = apply_scopes(policy_scope(::Freeby)).search_for_freeby(params[:query]).page(params[:page]).per(params[:per_page] || 15)
    else
    @freebies = apply_scopes(policy_scope(::Freeby)).page(params[:page]).per(params[:per_page] || 15)
    end
    authorize @freebies
  end

  def show

  end

  def new
    @freeby = Freeby.new
    authorize @freeby
  end

  def create
    @freeby = Freeby.new permitted_params.freeby
    authorize @freeby
    if @freeby.save
      redirect_to backend_freebies_url, notice: 'Freeby was successfully created.'
    else
      render :new, alert: 'Freeby was not created.'
    end
  end

  def update
    if @freeby.update_attributes permitted_params.freeby
      redirect_to backend_freebies_url, notice: 'Freeby was successfully updated.'
    else
      render :edit, alert: 'Freeby was not updated.'
    end
  end

  private

    def load_freeby
      @freeby = ::Freeby.find params[:id]
      authorize @freeby
    end

end
