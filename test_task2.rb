require 'watir'
require 'ox'


browser = Watir::Browser.new(:firefox, headless: true)
browser.goto("https://pm.healthcaresource.com/cs/chc#/search")

browser.button(text: "Search").click

browser.wait_until { browser.h3.text != 'Search Current Openings' }

while browser.button(text: "Load More").exists?
    browser.button(text: "Load More").click
end

job_links = []

browser.divs(class: "text-right").each do |div|
    div.links.each { |link| job_links << link }
end


jobs = job_links.map do |link|

    link.click(:control)
    browser.switch_window.use

    req_num = browser.element(css: 'div.margin-top-none:nth-child(1) > div:nth-child(1) > div:nth-child(1) > div:nth-child(1) > span:nth-child(1) > span:nth-child(2)').text
    vacancy_title = browser.element(css: 'h3.simple > span:nth-child(1) > strong:nth-child(1) > span:nth-child(1)').text
    vacancy_location = browser.element(css: 'div.field-column:nth-child(2)').text
    vacancy_URL = browser.url
    vacancy_id = vacancy_URL.split('/')[-1]
    vacancy_text = browser.element(css: 'div.row:nth-child(11) > div:nth-child(1)').text rescue vacancy_text = "No job description"

    browser.window.close
    browser.original_window.use

    {
        vacancy_id: vacancy_id,
        vacancy_title: vacancy_title,
        vacancy_URL: vacancy_URL,
        vacancy_location: vacancy_location,
        req_number: req_num,
        vacancy_text: vacancy_text
    }

end

doc = Ox::Document.new

src = Ox::Element.new('source')
doc << src

count = Ox::Element.new('jobs_count')
count << jobs.count.to_s
src << count

time = Ox::Element.new('generation_time')
time << Time.now.to_s
src << time

top = Ox::Element.new('jobs')
src << top

jobs.each do |hash|

    job = Ox::Element.new('job')
    top << job

    title = Ox::Element.new('title')
    title << hash[:vacancy_title]
    job << title
    
    url = Ox::Element.new('url')
    url << hash[:vacancy_URL]
    job << url

    id = Ox::Element.new('job_reference')
    id << hash[:vacancy_id]
    job << id

    location = Ox::Element.new('location')
    location << hash[:vacancy_location]
    job << location

    req = Ox::Element.new('req_number')
    req << hash[:req_number]
    job << req

    body = Ox::Element.new('body')
    body << hash[:vacancy_text]
    job << body
    
end

xml = Ox.dump(doc)

#puts xml

file = File.new("./test2.xml", "a:ASCII-8BIT")
file.print(xml)
file.close
