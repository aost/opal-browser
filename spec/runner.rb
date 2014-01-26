#! /usr/bin/env ruby
require 'selenium/webdriver'
require 'rest_client'
require 'json'

url = "http://#{ENV['BS_USERNAME']}:#{ENV['BS_AUTHKEY']}@hub.browserstack.com/wd/hub"
cap = Selenium::WebDriver::Remote::Capabilities.new

cap['platform']        = ENV['SELENIUM_PLATFORM'] || 'ANY'
cap['browser']         = ENV['SELENIUM_BROWSER'] || 'chrome'
cap['browser_version'] = ENV['SELENIUM_VERSION'] if ENV['SELENIUM_VERSION']

cap['browserstack.tunnel_identifier'] = ENV['TRAVIS_JOB_ID']
cap['browserstack.tunnel']            = 'true'

print 'Loading...'

begin
  loop do
    response = RestClient.get("https://#{ENV['BS_USERNAME']}:#{ENV['BS_AUTHKEY']}@www.browserstack.com/automate/plan.json")
    state    = JSON.parse(response.to_str)

    if state["parallel_sessions_running"] < state["parallel_sessions_max_allowed"]
      break
    end

    print '.'
    sleep 30
  end

  browser = Selenium::WebDriver.for(:remote, url: url, desired_capabilities: cap)
  browser.navigate.to('http://localhost:9292')
rescue Exception
  retry
end

print "\rRunning specs..."

begin
  Selenium::WebDriver::Wait.new(timeout: 1200, interval: 30).until {
    print '.'

    not browser.find_element(:css, 'p#totals').text.strip.empty?
  }

  totals   = browser.find_element(:css, 'p#totals').text
  duration = browser.find_element(:css, 'p#duration').find_element(:css, 'strong').text

  puts "\r#{totals} in #{duration}"

  if totals =~ / 0 failures/
    exit 0
  end
rescue Selenium::WebDriver::Error::NoSuchElementError
  puts "\rNo such element? You dun goof'd"
  puts
  puts browser.page_source
rescue Selenium::WebDriver::Error::TimeOutError
  puts "\rTimeout, have fun."
ensure
  browser.save_screenshot('screenshot.png')
  response = RestClient.post('https://api.imgur.com/3/upload',
    { image: File.open('screenshot.png') },
    { 'Authorization' => 'Client-ID 1979876fe2a097e' })

  puts
  puts JSON.parse(response.to_str)['data']['link']

  browser.quit
end

exit 1
