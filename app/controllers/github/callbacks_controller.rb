class Github::CallbacksController < Github::ApplicationController

  def index

    render json: params
  end
end
