# name: discourse-meetup
# about: meetup login provider
# version: 0.1
# author: Robin Ward, Dan Mills

require_dependency 'auth/oauth2_authenticator'

class MeetupAuthenticator < ::Auth::OAuth2Authenticator
  CLIENT_ID = ENV['MEETUP_APP_ID']
  CLIENT_SECRET = ENV['MEETUP_SECRET']

  def register_middleware(omniauth)
    omniauth.provider :oauth2,
                      :name => 'meetup',
                      :client_id => CLIENT_ID,
                      :client_secret => CLIENT_SECRET,
                      :scope => 'AccountInfoFull',
                      :provider_ignores_state => true,
                      :client_options => {
                        :site => 'https://api.meetup.com',
                        :authorize_url => 'https://secure.meetup.com/oauth2/authorize',
                        :token_url => 'https://secure.meetup.com/oauth2/access'
                      }
  end

  def after_authenticate(auth)
    result = Auth::Result.new
    token = URI.escape(auth['credentials']['token'])
    token.gsub!(/\+/, '%2B')

    user = JSON.parse(open("https://api.meetup.com/oauth2/member/self/?oauth_token=#{token}").read)
    result.name = user['name']

    current_info = ::PluginStore.get("meetup", "meetup_user_#{user['id']}")
    if current_info
      result.user = User.where(id: current_info[:user_id]).first
    end
    result.extra_data = { meetup_user_id: user['id'] }
    result
  end

  def after_create_account(user, auth)
    ::PluginStore.set("meetup", "meetup_user_#{auth[:extra_data][:meetup_user_id]}", {user_id: user.id })
  end

end

auth_provider :title => 'with Meetup',
              :authenticator => MeetupAuthenticator.new('meetup'),
              :message => 'Authorizing with Meetup (make sure pop up blockers are not enabled)',
              :frame_width => 600,
              :frame_height => 300

register_css <<CSS

  button.btn-social.meetup {
    background-color: #e0393e
  }

CSS
