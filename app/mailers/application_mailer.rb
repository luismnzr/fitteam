class ApplicationMailer < ActionMailer::Base
  default from: "Ana Gaby de Fit Team <hola@anagabyfitteam.com>"
  layout "mailer"

  helper :mailer
end
