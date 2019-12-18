class Backend::PromotionsController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_promotion, only: [:show, :edit, :update]

  def index
    if params[:query].present?
      @promotions = apply_scopes(policy_scope(::Promotion)).search_for_promotion(params[:query]).page(params[:page]).per(params[:per_page] || 15)
    else
    @promotions = apply_scopes(policy_scope(::Promotion)).page(params[:page]).per(params[:per_page] || 15)
    end
    authorize @promotions
  end

  def show

  end

  def new
    @promotion = Promotion.new
    authorize @promotion
  end

  def create
    @promotion = Promotion.new permitted_params.promotions
    authorize @promotion
    if @promotion.save
      redirect_to backend_promotions_url, notice: 'Promotion was successfully created.'
    else
      render :new, alert: 'Promotion was not created.'
    end
  end

  def update
    @promotion.available_plans = [] unless params["promotion"]["available_plans"].present?
    if @promotion.update_attributes permitted_params.promotions
      redirect_to backend_promotions_url, notice: 'Promotion was successfully updated.'
    else
      render :edit, alert: 'Promotion was not updated.'
    end
  end

  private

    def load_promotion
      @promotion = ::Promotion.find params[:id]
      authorize @promotion
    end

end
