class Backend::Box::ProductsController < Backend::BackendController

  # after_action :verify_authorized
  before_filter :load_box

  def index
    if params[:query].present?
      @box_products = apply_scopes(policy_scope(@box.box_products)).includes([:product]).search_for_box_product(params[:query]).page(params[:page]).per(params[:per_page] || 20)
    else
      @box_products = apply_scopes(policy_scope(@box.box_products)).includes([:product]).page(params[:page]).per(params[:per_page] || 20)
    end
    authorize @box_products
  end

  def search
    if params[:query].present?
      @products = apply_scopes(policy_scope(Product.active.box_stock)).search_for_product(params[:query]).page(params[:page]).per(params[:per_page] || 15)
    else
      @products = apply_scopes(policy_scope(Product.active.box_stock)).page(params[:page]).per(params[:per_page] || 15)
    end
    authorize @products
  end

  def create
    @products = Product.where(id: params[:product_ids])
    @products.each do |product|
      @box.box_products.create(product_id: product.id)
    end
    @box.reload
  end

  def update
    @box_product = @box.box_products.find params[:id]

    if params[:increment] == "add"
      @box_product.increment!(:quantity, 1)
    else
      @box_product.decrement!(:quantity, 1) unless @box_product.quantity == 1
    end
    render json: { box_product: @box_product } , status: :accepted
  end

  def destroy
    @box_product = @box.box_products.find params[:id]
    @box_product.destroy
    authorize @box_product
  end

  private

    def load_box
      @box = ::Box.includes([:products]).find params[:box_id]
      # authorize @box
    end

end
