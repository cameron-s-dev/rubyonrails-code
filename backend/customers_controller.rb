class Backend::CustomersController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_customer, only: [:show, :edit, :update, :destroy, :review]

  def index
    if params[:query].present?
      @customers = apply_scopes(policy_scope(User.customers)).search_for_user(params[:query]).page(params[:page]).per(params[:per_page] || 15)
    else
      @customers = apply_scopes(policy_scope(User.customers)).page(params[:page]).per(params[:per_page] || 15)
    end
    authorize @customers
  end

  def show
  end

  def edit
  end

  # def new
  #   @customer = Customer.new
  #   authorize @customer
  # end
  #
  # def create
  #   @customer = Customer.new permitted_params.user
  #   authorize @customer
  #   if @customer.save
  #     redirect_to backend_customer_path(@customer), notice: 'Customer was successfully created.'
  #   else
  #     render :new, alert: 'Customer was not created.'
  #   end
  # end

  def update
    if @customer.update_attributes permitted_params.user
      redirect_to backend_customer_path(@customer), notice: 'Customer was successfully updated.'
    else
      render :edit, alert: 'Customer was not updated.'
    end
  end

  def destroy
    @customer.destroy
    redirect_to backend_customers_path, notice: 'Customer Removed'
  end

  private

    def load_customer
      @customer = User.find params[:id]
      authorize @customer
    end
end
