class Backend::FaqsController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_category, only: [:edit, :update, :destroy]

  def index
    @categories = FaqCategory.all
    authorize @categories
  end

  def new
    @category = FaqCategory.new
    authorize @category
  end

  def create
    @category = FaqCategory.new permitted_params.faq_category
    authorize @category
    if @category.save
      redirect_to backend_faqs_path, notice: 'Category was successfully created.'
    else
      render :new, alert: 'Category was not created.'
    end
  end

  def edit

  end

  def update
    authorize @category
    if @category.update_attributes permitted_params.faq_category
      redirect_to backend_faqs_path, notice: 'Category was successfully updated.'
    else
      render :edit, alert: 'Category was not created.'
    end
  end

  def destroy
    @category.destroy
    authorize @category
    redirect_to backend_faqs_path, notice: 'Category Removed'
  end

  private
    def load_category
      @category = ::FaqCategory.find params[:id]
      authorize @category
    end


end
