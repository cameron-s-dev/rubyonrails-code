class Backend::ReportsController < Backend::BackendController

  # after_action :verify_authorized, except: [:show]

  def index
  end

  def generate_csv
    respond_to do |format|
      format.html {
        if params[:box_id]
          ReportWorker.perform_async current_user.email, params[:report_type], params[:box_id]
        else
          ReportWorker.perform_async current_user.email, params[:report_type]
        end
        redirect_to({ action: 'index' }, notice: 'Your report is being generated and you will receive an email soon')
      }
    end
  end


  def retrieve_report
    case params.fetch(:report_type, 'subscription_report')
      when 'subscription_report'
        return Csv::SubscriptionExport.new.csv
    end
    case params.fetch(:report_type, 'health_profile_report')
      when 'health_profile_report'
        return Csv::HealthProfileExport.new.csv
    end
    case params.fetch(:report_type, 'users_report')
      when 'users_report'
        return Csv::UsersExport.new.csv
    end
    case params.fetch(:report_type, 'box_order_report')
      when 'box_order_report'
        box = ::Box.find params[:box_id]
        return Csv::BoxOrdersExport.new(box).csv
    end
  end
end
