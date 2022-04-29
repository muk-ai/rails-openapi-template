class V1::TasksController < ApplicationController
  def index
    render json: { tasks: [] }
  end

  def show
    render json: { id: params[:id] }
  end
end
