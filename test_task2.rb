require 'mechanize'
require 'ox'
require 'json'


agent = Mechanize.new

request = {"query":{"bool":{"must":{"match_all":{}},"should":{"match":{"userArea.isFeaturedJob":{"query":true,"boost":1}}}}},"sort":{"title.raw":"asc"},"aggs":{"facility":{"terms":{"field":"userArea.bELevel1.raw","size":1000}},"occupationalCategory":{"terms":{"field":"occupationalCategory.raw","size":1000}},"employmentType":{"terms":{"field":"employmentType.raw","size":1000}}}}

page = agent.post(
    'https://pm.healthcaresource.com/JobseekerSearchAPI/chc/api/Search?size=500',
    request.to_json,
    {'Content-Type' => 'application/json'}
    )

content = page.body
content = JSON.parse(content.gsub('=>', ':'))

all = content["hits"]["hits"]


jobs = all.map do |elem|

    vacancy_title = elem["_source"]["title"]
    vacancy_location = elem["_source"]["jobLocation"]["address"]["addressLocalityRegion"]
    vacancy_URL = "https://pm.healthcaresource.com/cs/chc#/job/" + elem["_source"]["userArea"]["jobPostingID"].to_s
    vacancy_id = elem["_source"]["userArea"]["jobPostingID"]
    vacancy_text = elem["_source"]["userArea"]["jobSummary"]

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
    id << hash[:vacancy_id].to_s
    job << id

    location = Ox::Element.new('location')
    location << hash[:vacancy_location]
    job << location

    body = Ox::Element.new('body')
    body << hash[:vacancy_text].to_s
    job << body
    
end

xml = Ox.dump(doc)

#puts xml

file = File.new("./test2.xml", "a:ASCII-8BIT")
file.print(xml)
file.close

