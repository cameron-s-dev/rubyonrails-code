class Backend::Cms::CmsContentController < Backend::BackendController

  after_action :verify_authorized
  before_filter :load_cms_content, only: [:show, :edit, :update]

  def index
    @cms_contents = CmsContent.order(:name)
    authorize @cms_contents
  end

  def show
  end

  def edit
    @cms_content.cms_images.build unless @cms_content.cms_images.present?
  end

  def update
    if @cms_content.update_attributes permitted_params.cms_content
      redirect_to backend_cms_path, notice: 'CMS Category was successfully updated.'
    else
      render :edit, alert: 'CMS Category was not updated.'
    end
  end

  private

    def load_cms_content
      @cms_content = CmsContent.friendly.find params[:id]
      authorize @cms_content
    end

end
