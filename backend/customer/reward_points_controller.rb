class Backend::Customer::RewardPointsController < Backend::BackendController

  before_filter :load_customer
  before_filter :reward_points_total

  def new
    @reward_points = @customer.reward_points_histories.new
  end

  def index
    @reward_points = @customer.reward_points_histories.order(created_at: :desc)
  end

  def create
    @reward_points = @customer.reward_points_histories.new permitted_params.reward_points_history
    respond_to do |format|
      if @reward_points.save
        format.json { render json:{ errors: nil, message: 'Successfully saved reward point adjustment', redirect_url: backend_customer_reward_points_path(@customer) }, status: :ok }
      else
        format.json { render json:{ errors: @reward_points.errors, message: 'Errors saving adjustment' }, status: :unprocessable_entity }
      end
    end
  end

  private

    def load_customer
      @customer = User.find params[:customer_id]
    end

    def reward_points_total
      @reward_points_total = @customer.reward_points
    end

end
