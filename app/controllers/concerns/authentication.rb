module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :authenticate, **options
    end
  end

  private

  def authenticate
    raw_token = bearer_token
    return unauthorized unless raw_token

    token = Token.find_by(digest: Token.digest(raw_token))
    return unauthorized unless token

    @current_user = token.user
  end

  def current_user
    @current_user
  end

  def bearer_token
    authorization = request.headers["Authorization"]
    return if authorization.blank?

    scheme, token = authorization.split(" ", 2)
    return unless scheme == "Bearer"
    return if token.blank?

    token
  end

  def unauthorized
    render json: {
      errors: [ { status: 401, title: "Unauthorized", detail: "Authentication token is missing or invalid." } ]
    }, status: :unauthorized
  end
end
