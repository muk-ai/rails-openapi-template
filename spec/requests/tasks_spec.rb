require 'rails_helper'

RSpec.describe "Tasks", type: :request do
  describe "GET /tasks" do
    it "returns 200" do
      get '/v1/tasks'
      expect(response).to have_http_status(200)
    end
  end

  describe "GET /tasks/:id" do
    it "returns 200" do
      get '/v1/tasks/1'
      expect(response).to have_http_status(200)
    end
  end
end
