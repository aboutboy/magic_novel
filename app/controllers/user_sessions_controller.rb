class UserSessionsController < ApplicationController
  # omniauth callback method
  def create
    omniauth = request.env['omniauth.auth']
    logger.debug "+++ #{omniauth}"

    redirect_to root_path
  end

  # Omniauth failure callback
  def failure
    flash[:notice] = params[:message]
  end

  # logout - Clear our rack session BUT essentially redirect to the provider
  # to clean up the Devise session from there too !
  def logout
    session[:uid] = nil

    # flash[:notice] = 'You have successfully signed out!'
    redirect_to "#{Setting.CUSTOM_PROVIDER_URL}/users/sign_out"
  end
end