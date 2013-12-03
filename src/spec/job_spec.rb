require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'pp'

describe 'AppConverter tests' do
    it "job list should be empty" do
        get "/job"

        body = JSON.parse last_response.body

        body.size.should eql(0)
    end

    it "should not be able to create a new job if the the associated " <<
            "appliance does not exist" do
        post '/job', File.read(EXAMPLES_PATH + '/job1.json')
        last_response.status.should == 404
    end

    it "appliance list should be empty" do
        get "/appliance"

        body = JSON.parse last_response.body

        body.size.should eql(0)
    end

    it "should create a new appliance" do
        post '/appliance', File.read(EXAMPLES_PATH + '/appliance1.json')
        body = JSON.parse last_response.body

        $new_oid = body['_id']['$oid']
    end

    it "should be able to retrieve metadata of the new appliance" do
        get "/appliance/#{$new_oid}"

        body = JSON.parse last_response.body

        body['_id']['$oid'].should == $new_oid
        body['name'].should == 'CentOS'
    end

    it "should not be able to retrieve metadata of the non exixting appliance" do
        get "/appliance/aaaa"
        last_response.status.should == 404
    end

    it "appliance list should contain 1 element" do
        get "/appliance"

        body = JSON.parse last_response.body

        body.size.should eql(1)

        get "/job"

        body = JSON.parse last_response.body

        body.size.should eql(1)
    end

    it "should create a new job" do
        hash = JSON.parse(File.read(EXAMPLES_PATH + '/job1.json'))
        hash['appliance_id'] = $new_oid

        post '/job', hash.to_json
        body = JSON.parse last_response.body

        $new_job_oid = body['_id']['$oid']
    end

    it "should be able to retrieve metadata of the new job" do
        get "/job/#{$new_job_oid}"

        body = JSON.parse last_response.body

        body['_id']['$oid'].should == $new_job_oid
        body['name'].should == 'convert'
        body['status'].should == 'pending'
        body['creation_time'].should <= Time.now.to_i
    end

    it "should not be able to retrieve metadata of the non exixting job" do
        get "/job/aaaa"
        last_response.status.should == 404
    end

    it "job list should contain 1 element" do
        get "/job"

        body = JSON.parse last_response.body
        body.size.should eql(2)
    end

    it "should delete the given job" do
        delete "/job/#{$new_job_oid}"
        last_response.status.should == 200

        get "/job"

        body = JSON.parse last_response.body

        body.size.should eql(1)
    end

    it "should not be able to delete a non existing job" do
        delete "/job/aaa"
        last_response.status.should == 404
    end

    it "should delete the given appliance" do
        delete "/appliance/#{$new_oid}"
        last_response.status.should == 200

        get "/appliance"

        body = JSON.parse last_response.body

        body.size.should eql(0)

        get "/job"

        body = JSON.parse last_response.body

        # TODO Check status
        body.size.should eql(1)
    end


    it "should not be able to delete a non existing appliance" do
        delete "/appliance/aaa"
        last_response.status.should == 404
    end
end
