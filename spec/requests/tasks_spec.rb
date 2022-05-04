require 'rails_helper'

RSpec.describe "Tasks", type: :request do
  include Committee::Rails::Test::Methods

  def committee_options
    @committee_options ||= {
      schema_path: Rails.root.join('schema', 'schema.yaml').to_s,
      query_hash_key: 'rack.request.query_hash',
      parse_response_by_content_type: false,
    }
  end

  describe "GET /tasks" do
    it "returns 200" do
      get '/v1/tasks'
      assert_response_schema_confirm(200)
    end
  end

  describe "GET /tasks/:id" do
    it "returns 200" do
      get '/v1/tasks/1'
      assert_response_schema_confirm(200)
    end
  end
end
