class ApiController < ActionController::API

  include ActionController::MimeResponds
  respond_to :json

  before_action :json_authenticate_user!

  rescue_from ActiveRecord::RecordNotFound do |error|
    model = error.message.match(/Couldn't find (?<model>\w+)/)[:model]
    render(
      json: { error: "Le/La #{model} n'as pas été trouvé" },
      status: :not_found
    )
  end

  rescue_from CanCan::AccessDenied do |error|
    render(
      json: { error: 'Unauthorized' },
      status: :unauthorized
    )
  end

  protected

  def json_authenticate_user!
    authenticate_user!

    head :unauthorized if current_user.nil?
  end
end
