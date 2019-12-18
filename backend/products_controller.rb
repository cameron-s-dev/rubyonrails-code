class Backend::ProductsController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_product, only: [:show, :edit, :update, :destroy]

  def index
    if params[:query].present?
      @products = apply_scopes(policy_scope(::Product.all)).search_for_product(params[:query]).page(params[:page]).per(params[:per_page] || 15)
    else
      @products = apply_scopes(policy_scope(::Product.all)).page(params[:page]).per(params[:per_page] || 15)
    end
    authorize @products
  end

  def show
  end

  def edit
  end

  def new
    @product = ::Product.new
    authorize @product
  end

  def create
    @product = ::Product.new permitted_params.product
    authorize @product
    if @product.save
      redirect_to [:backend, @product], notice: 'Product was successfully created.'
    else
      render :new, alert: 'Product was not created.'
    end
  end

  def update
    if @product.update_attributes permitted_params.product
      redirect_to [:backend, @product], notice: 'Product was successfully updated.'
    else
      render :edit, alert: 'Product was not updated.'
    end
  end

  private

    def load_product
      @product = ::Product.find params[:id]
      authorize @product
    end

end
