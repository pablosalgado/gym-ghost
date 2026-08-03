require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  include_context 'with OpenAPI contract'
  describe 'GET /api/v1/schedule' do
    it 'returns unauthorized when header is missing' do
      get '/api/v1/schedule', params: { city_id: 1, facility_id: 1, date: '2026-07-21' }

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
      get '/api/v1/schedule',
          params: { city_id: 1, facility_id: 1, date: '2026-07-21' },
          headers: { 'Authorization' => 'Bearer invalid-token' }

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
      city = create(:city)
      facility = create(:facility, city:)
      service = instance_double(Partner::ActivitiesService, fetch: [])
      allow(Partner::ActivitiesService).to receive(:new).and_return(service)

      get '/api/v1/schedule',
          params: { city_id: city.id, facility_id: facility.id, date: '2026-07-21' },
          headers: { 'Authorization' => "Bearer #{raw_token}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('schedule')
    end
  end
end
