class Backend::Customer::AddressesController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_customer, only: [:show, :index, :edit, :update]
  before_filter :load_address, only: [:show, :edit, :update]

  def index
    @addresses = @customer.addresses.page(params[:page]).per(params[:per_page])
    authorize @addresses
  end

  def edit
  end

  def show
    address = @customer.addresses.find(params[:id])
  end

  def update
    if @address.update_attributes permitted_params.address
      redirect_to edit_backend_customer_address_url(@customer, @address), notice: 'Address was successfully updated.'
    else
      render :edit, alert: 'Address was not updated.'
    end
  end

  private

  def load_customer
    @customer = User.customers.find params[:customer_id]
    authorize @customer
  end

  def load_address
    @address = @customer.addresses.find params[:id]
    authorize @address
  end

end
