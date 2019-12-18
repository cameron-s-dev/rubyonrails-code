class Backend::OneOffBoxesController < Backend::BackendController

  after_action :verify_authorized

  def index
    if params[:query].present?
      @boxes = apply_scopes(policy_scope(::Box)).search_for_box(params[:query]).one_off.order(:date).page(params[:page]).per(params[:per_page] || 100)
    else
      @boxes = apply_scopes(policy_scope(::Box)).one_off.page(params[:page]).order(:date).per(params[:per_page] || 100)
    end
    authorize @boxes
  end

end
