require 'mechanize'
require 'ox'

agent = Mechanize.new
page = agent.get("http://jobs.pmz.com/mcc/pmz/listingpage.htm")

job_links = page.links_with(text: 'View')

jobs = job_links.map do |link|

    job = link.click
    vacancy_title = job.search("h1").text
    vacancy_location = job.search("h4").text
    vacancy_URL = link.href
    vacancy_id = vacancy_URL.split('-')[2].split('.')[0]
    vacancy_text = job.search(".top-margin").text

    {
        vacancy_id: vacancy_id,
        vacancy_title: vacancy_title,
        vacancy_URL: vacancy_URL,
        vacancy_location: vacancy_location,
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

    body = Ox::Element.new('body')
    body << hash[:vacancy_text]
    job << body
    
end

xml = Ox.dump(doc)

#puts xml

file = File.new("./test1.xml", "a:UTF-8")
file.print(xml)
file.close