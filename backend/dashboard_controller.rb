class Backend::DashboardController < Backend::BackendController

  def index
    @current_month_breakdown = MonthlyBreakdown.new(Date.today.beginning_of_month)
    @next_month_breakdown    = MonthlyBreakdown.new(Date.today.beginning_of_month+1.month)

    @allocator_queue    = Sidekiq.redis { |r| r.lrange "queue:box_allocator", 0, -1 }
    @dispatcher_queue   = Sidekiq.redis { |r| r.lrange "queue:box_orders_dispatcher", 0, -1 }
  end

end
