class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :json_authenticate_user!

  private

  def respond_with(resource, opts = {})
    if resource.errors.empty?
      render json: resource
    else
      render json: { errors: resource.errors }, status: :unprocessable_entity
    end
  end

end
