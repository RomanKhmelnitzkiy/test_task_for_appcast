require 'mechanize'
require 'ox'
require 'json'

class Parser

    def self.get_page(url, request)

        agent = Mechanize.new

        page = agent.post(
            url,
            request.to_json,
            {'Content-Type' => 'application/json'}
            )

        content = page.body
        content = JSON.parse(content.gsub('=>', ':'))

        all = content["hits"]["hits"]
    end

    def self.get_jobs(page)

        jobs = page.map do |elem|

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

    end

end

class XML

    attr_accessor :xml

    def initialize(xml)

        doc = Ox::Document.new

        src = Ox::Element.new('source')
        doc << src

        count = Ox::Element.new('jobs_count')
        count << xml.count.to_s
        src << count

        time = Ox::Element.new('generation_time')
        time << Time.now.to_s
        src << time

        top = Ox::Element.new('jobs')
        src << top

        xml.each do |hash|

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

        @xml = Ox.dump(doc)

    end

    def input
        puts xml
    end

    def input_in_file
        file = File.new("./test2.xml", "a:ASCII-8BIT")
        file.print(xml)
        file.close
    end

end



request = {"query":{"bool":{"must":{"match_all":{}},"should":{"match":{"userArea.isFeaturedJob":{"query":true,"boost":1}}}}},"sort":{"title.raw":"asc"},"aggs":{"facility":{"terms":{"field":"userArea.bELevel1.raw","size":1000}},"occupationalCategory":{"terms":{"field":"occupationalCategory.raw","size":1000}},"employmentType":{"terms":{"field":"employmentType.raw","size":1000}}}}
url = 'https://pm.healthcaresource.com/JobseekerSearchAPI/chc/api/Search?size=500'

page = Parser::get_page(url, request)
jobs = Parser::get_jobs(page)

document = XML.new(jobs)

document.input_in_file


