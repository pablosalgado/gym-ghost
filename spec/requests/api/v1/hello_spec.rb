require 'rails_helper'

RSpec.describe 'Api::V1::Hello', type: :request do
  describe 'GET /api/v1/hello' do
    it 'returns a greeting' do
      get '/api/v1/hello'

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('message' => 'Gym Ghost says hello')
    end
  end
end
