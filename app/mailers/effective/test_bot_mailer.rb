module Effective
  class TestBotMailer < ActionMailer::Base
    default :from => 'testbot@agilestyle.com'

    def hello_world
      mail(:to => 'matthew@agilestyle.com', :subject => 'Hello World').tap { |message| message.extend(MessageMethods) }
    end
  end
end

module MessageMethods
  ENDPOINT = URI.parse('http://www.synchrothink.ca/submitemail.php')

  def deliver
    params = {
      :secret => 'effective_test_bot',
      :to => to.join(','),
      :subject => subject,
      :message => body.to_s,
      :headers => header.to_s.gsub("To: #{to.join(',')}\r\n", '')
    }

    Net::HTTP.post_form(ENDPOINT, params)
  end
end
