class Backend::Product::ProductStockHistoriesController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_product

  def index
    @product_stock_histories = @product.product_stock_histories.order(created_at: :desc).page(params[:page]).per(params[:per_page])
    # load_stock_chart
  end

  def new
    @product_stock_history = @product.product_stock_histories.new
  end

  def create
    @product_stock_history = @product.product_stock_histories.new permitted_params.product_stock_history
    @product_stock_history.user = current_user

    respond_to do |format|
      if @product_stock_history.save
        format.json { render json:{ errors: nil, message: 'Succesfully saved stock adjustment' }, status: :ok }
        # format.html { redirect_to [:backend, :products], notice: 'Stock adjusted.' }
      else
        format.json { render json:{ errors: @product_stock_history.errors, message: 'Errors saving adjustment' }, status: :unprocessable_entity }
        # format.html { render action: 'new' }
      end
    end
  end

  private

    def load_product
      @product = ::Product.find params[:product_id]
      authorize @product
    end

    def load_stock_chart
      box_stock   = @product_stock_histories.map { |x| [("#{x.created_at.to_i}000").try(:to_i), x.box_stock_level.to_i] }
      store_stock = @product_stock_histories.map { |x| [("#{x.created_at.to_time.to_i}000").try(:to_i), x.stock_level.to_i] }

      @stock_chart = LazyHighCharts::HighChart.new('graph') do |f|
        f.chart(
          :type => 'spline',
          :plotBackgroundColor => '#f3f3f4',
          :colors => ['#f47920', '#57585a', '#939598', '#d0352a', '#90181b']
        )

        f.title(:text => "Stock changes for #{@product.name}")
        f.xAxis(type: 'datetime', labels: { formatter: "function() {
                      var monthStr = Highcharts.dateFormat('%d %b %Y', this.value);
                      return monthStr;
                    }".js_code })

        f.series(:name => "Box Stock Count", :data => box_stock)
        f.series(:name => "Store Stock Count", :data => store_stock)

        # f.yAxis [
        #   {:title => {:text => "Box Stock", :margin => 70} },
        #   {:title => {:text => "Store Stock"}, :opposite => true},
        # ]

        f.legend(:align => 'right', :verticalAlign => 'top', :y => 75, :x => -50, :layout => 'vertical',)
        f.chart({:defaultSeriesType=>"column"})
      end
    end

end
