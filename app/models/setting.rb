# RailsSettings Model
class Setting < Settingslogic
  source "#{Rails.root}/config/services.yml"
  namespace Rails.env
end