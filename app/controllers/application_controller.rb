class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

  private

  def not_found
    render json: {
      errors: [ { status: 404, title: "Not Found", detail: "The requested resource does not exist." } ]
    }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: {
      errors: [ { status: 422, title: "Validation Failed", detail: exception.record.errors.full_messages.join(", ") } ]
    }, status: :unprocessable_entity
  end
end
