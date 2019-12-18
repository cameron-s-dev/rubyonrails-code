class Backend::Customer::InvoicesController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_customer, only: [:index, :show, :edit, :update]

  def index
    @invoices = ChargeBee::Invoice.invoices_for_customer(@customer.chargebee_customer_id, :limit => 10) if @customer.chargebee_customer_id.present?
  end

  def show
    begin
      invoice_pdf = ChargeBee::Invoice.pdf(params[:id])
      redirect_to invoice_pdf.download.download_url
    rescue => e
      redirect_to backend_customer_invoices_url(@customer), alert: 'There was a problem getting the invoice. Try again later.'
    end
  end

  private

  def load_customer
    @customer = User.customers.find params[:customer_id]
    authorize @customer
  end

end
