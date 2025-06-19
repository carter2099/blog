class ApplicationController < ActionController::Base
  include Authentication
  # This is a bit too restrictive by default I think
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
end
