RSpec.configure do |config|
  config.add_setting :committee_options
  config.committee_options = {
    schema_path: Rails.root.join('schema', 'schema.yaml').to_s,
    query_hash_key: 'rack.request.query_hash',
    prefix: '/v1',
    parse_response_by_content_type: false,
  }
  config.include Committee::Rails::Test::Methods, type: :request
end
