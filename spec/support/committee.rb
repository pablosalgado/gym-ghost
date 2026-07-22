require "committee"

RSpec.shared_context "with OpenAPI contract" do
  def app
    @_committee_app ||= Committee::Middleware::RequestValidation.new(
      Rails.application,
      schema: committee_schema,
      strict: true,
      check_content_type: false,
    )
  end

  private

  def committee_schema
    @_committee_schema ||= Committee::Drivers.load_from_file(
      Rails.root.join("docs/openapi.yml")
    )
  end
end
