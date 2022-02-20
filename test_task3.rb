require 'mechanize'
require 'ox'

agent = Mechanize.new
page = agent.get("https://kiloutou.gestmax.fr/search/all-vacsearchfront_localisation-all/mobilite-afficher-tout")

jobs = []

loop do

    job_links = page.links_with(href: %r{https://kiloutou.gestmax.fr/\d+})

    job_links.each do |link|

        job = link.click
        vacancy_title = job.search("h1").text
        vacancy_location = job.search(".title-city").text
        vacancy_URL = link.href
        vacancy_id = vacancy_URL.split('/')[3]
        vacancy_text = job.search(".vacancy-text").text
        
        jobs <<
        {
            vacancy_id: vacancy_id,
            vacancy_title: vacancy_title,
            vacancy_URL: vacancy_URL,
            vacancy_location: vacancy_location,
            vacancy_text: vacancy_text
        }
        
    end

    break if page.link_with(text: 'Suivant »').href === "#"
    l = page.link_with(text: 'Suivant »')
    page = l.click

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

file = File.new("./test3.xml", "a:ASCII-8BIT")
file.print(xml)
file.close