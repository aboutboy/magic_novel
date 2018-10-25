require 'omniauth-oauth2'
require "./app/models/setting"
module OmniAuth
  module Strategies
    class Github < OmniAuth::Strategies::OAuth2
      option :client_options,  {
          :site => 'https://github.com/api/v3',
          :authorize_url => 'https://github.com/login/oauth/authorize',
          :token_url => 'https://github.com/login/oauth/access_token',
      }
    end
  end
end