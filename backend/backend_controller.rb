class Backend::BackendController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin

  layout "backend"
  respond_to :html

  def authenticate_admin
    unless current_user && current_user.has_role?(:admin)
      redirect_to root_path, alert: 'Unable to access backend. Must be a logged in Admin.'
    end
  end
end
