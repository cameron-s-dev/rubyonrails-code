class Backend::Customer::HealthProfileController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_customer

  def show
    @health_profile_questionaire = @customer.health_profile_questionaire
  end

  private

  def load_customer
    @customer = User.customers.find params[:customer_id]
    authorize @customer
  end

end
