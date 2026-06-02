require "rails_helper"

RSpec.describe "Bootstrap styling", type: :request do
  it "renders Bootstrap classes on the sign-in page" do
    get new_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("bootstrap@5/dist/css/bootstrap.min.css")
    expect(response.body).to include('class="form-control"')
    expect(response.body).to include('class="btn btn-primary"')
    expect(response.body).not_to include("text-4xl")
  end

  it "renders Bootstrap classes on the forgot password page" do
    get new_password_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('class="form-control"')
    expect(response.body).to include('class="btn btn-primary"')
    expect(response.body).not_to include("text-4xl")
  end

  it "renders Bootstrap classes on the password reset page" do
    user = create(:user)

    get edit_password_path(user.password_reset_token)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('class="form-control"')
    expect(response.body).to include('class="btn btn-primary"')
    expect(response.body).not_to include("text-4xl")
  end
end
