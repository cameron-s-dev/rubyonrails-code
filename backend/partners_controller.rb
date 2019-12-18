class Backend::PartnersController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_partner, only: [:show, :edit, :update, :destroy]

  def index
    if params[:query].present?
      @partners = apply_scopes(policy_scope(Partner)).search_for_partner(params[:query]).page(params[:page]).per(params[:per_page] || 15)
    else
      @partners = apply_scopes(policy_scope(Partner)).page(params[:page]).per(params[:per_page] || 15)
    end
    authorize @partners
  end

  def show
  end

  def edit
  end

  def new
    @partner = Partner.new
    authorize @partner
  end

  def create
    @partner = Partner.new permitted_params.partner
    authorize @partner
    if @partner.save
      redirect_to [:backend, @partner], notice: 'Partner was successfully created.'
    else
      render :new, alert: 'Partner was not created.'
    end
  end

  def update
    if @partner.update_attributes permitted_params.partner
      redirect_to [:backend, @partner], notice: 'Partner was successfully updated.'
    else
      render :edit, alert: 'Partner was not updated.'
    end
  end

  private

    def load_partner
      @partner = Partner.friendly.find params[:id]
      authorize @partner
    end

end
