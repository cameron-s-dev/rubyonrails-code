class Backend::Box::BoxQuantityHistoriesController < Backend::BackendController
  before_filter :load_box

  def index
  end

  def new
    @box_quantity_history = @box.box_quantity_histories.new
  end

  def create
    @box_quantity_history = @box.box_quantity_histories.create permitted_params.box_quantity_history
  end


private

  def load_box
    @box = ::Box.includes([:box_quantity_histories]).find(params[:id]).decorate
  end

end