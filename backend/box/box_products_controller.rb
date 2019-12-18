class Backend::Box::BoxProductsController < Backend::BackendController

  before_filter :load_box
  before_filter :load_box_product

  def update

  end

private

  def load_box
    @box = Box.find params[:box_id]
  end

  def load_box_product
    @box_product = @box.box_products.find params[:id]
    authorize @box_product
  end

end