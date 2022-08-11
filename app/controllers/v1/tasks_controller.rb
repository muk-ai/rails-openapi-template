class V1::TasksController < ApplicationController
  def index
    render json: []
  end

  def show
    render json: {
      id: params[:id].to_i,
      description: 'description',
    }
  end
end
