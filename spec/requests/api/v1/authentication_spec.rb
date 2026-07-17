require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  describe 'GET /api/v1/hello' do
    it 'returns unauthorized when header is missing' do
      get '/api/v1/hello'

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        'errors' => [
          {
            'status' => 401,
            'title' => 'Unauthorized',
            'detail' => 'Authentication token is missing or invalid.'
          }
        ]
      )
    end

    it 'returns unauthorized when token is invalid' do
      get '/api/v1/hello', headers: { 'Authorization' => 'Bearer invalid-token' }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        'errors' => [
          {
            'status' => 401,
            'title' => 'Unauthorized',
            'detail' => 'Authentication token is missing or invalid.'
          }
        ]
      )
    end

    it 'authenticates when token is valid' do
      user = create(:user)
      raw_token = SecureRandom.hex(32)
      create(:token, user:, digest: Token.digest(raw_token))

      get '/api/v1/hello', headers: { 'Authorization' => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('message' => 'Gym Ghost says hello')
    end
  end
end
