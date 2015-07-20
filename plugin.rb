# name: discourse-meetup
# about: meetup login provider
# version: 0.1
# author: Robin Ward, Dan Mills

gem 'omniauth-meetup', '0.0.7'

class MeetupAuthenticator < ::Auth::Authenticator
  CLIENT_ID = ENV['MEETUP_APP_ID']
  CLIENT_SECRET = ENV['MEETUP_SECRET']

  def name()
    'meetup'
  end

  def register_middleware(omniauth)
    omniauth.provider :meetup, ENV['MEETUP_APP_ID'], ENV['MEETUP_SECRET']
  end

  def after_authenticate(auth)
    result = Auth::Result.new
    result.name = auth['name']
    current_info = ::PluginStore.get("meetup", "meetup_user_#{auth['info']['id']}")
    if current_info
      result.user = User.where(id: current_info[:user_id]).first
    end
    result.extra_data = { meetup_user_id: auth['info']['id'] }
    result
  end

  def after_create_account(user, auth)
    ::PluginStore.set("meetup", "meetup_user_#{auth[:extra_data][:meetup_user_id]}", {user_id: user.id })
  end

end

auth_provider :title => 'with Meetup',
              :authenticator => MeetupAuthenticator.new(),
              :message => 'Authorizing with Meetup (make sure pop up blockers are not enabled)',
              :frame_width => 600,
              :frame_height => 300

register_css <<CSS

  button.btn-social.meetup {
    background-color: #e0393e
  }

CSS
