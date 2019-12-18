class Backend::ReviewsController < Backend::BackendController

  after_action :verify_authorized, except: [:show]

  def index
    # if params[:query].present?
    #   @reviews = apply_scopes(policy_scope(::Review)).s(params[:query]).order(:date).page(params[:page]).per(params[:per_page] || 100)
    # else
    @reviews = apply_scopes(policy_scope(::Review)).includes(review_responses: [:reviewable]).page(params[:page]).order(:name).per(params[:per_page] || 100)
    # end
    authorize @reviews
  end


  def show
    @review = Review.find params[:id]

    respond_to do |format|
      format.html {}
      format.csv {
        csv_export = Csv::ReviewExport.new(find_reviewable).csv
        send_file csv_export, :x_sendfile=>true
        # send_file csv_export.file,
        #   :type => "text/xlsx; charset=UTF-8;",
        #   :disposition => "attachment",
        #   :filename=> "/public/export.xlsx"
      }
    end
  end

  def find_reviewable
    name = params.fetch(:reviewable_type, "")
    if name.present?
      return name.classify.constantize.find params.fetch(:reviewable_id, "")
    end
    nil
  end

end
