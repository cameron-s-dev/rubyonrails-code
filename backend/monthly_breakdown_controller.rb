class Backend::MonthlyBreakdownController < Backend::BackendController

  before_filter :redirect_to_show, only: [:index]
  before_filter :load_breakdown
  before_filter :load_allocations, only: [:allocations]

  decorates_assigned :box_subscriptions

  def index
  end

  def show
  end

  def allocations
  end

  private

    def redirect_to_show
      redirect_to backend_monthly_breakdown_url(params[:id]) if params[:id].present?
    end

    def load_allocations
      case params.fetch(:allocation_type, "")
      when "eligible" then
        @box_subscriptions = @breakdown.eligible
      when "not_eligible" then
        @box_subscriptions = @breakdown.not_eligible
      else
        @box_subscriptions = @breakdown.allocated
      end
    end

    def load_breakdown
      begin
        @date      = params.fetch(:id, Date.today.to_s)
        @breakdown = MonthlyBreakdown.new(Date.parse(@date))
      rescue => e
        redirect_to backend_monthly_breakdown_index_url, alert: "No Breakdown for selected Month. #{e.message}"
      end
    end

end
