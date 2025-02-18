class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  before_action :ensure_json_request

  def ensure_json_request
    return if request.format.json?
    render nothing: true, status: 406
  end

end
