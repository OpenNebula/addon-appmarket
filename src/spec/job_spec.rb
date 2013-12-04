require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'pp'

describe 'AppConverter tests' do
describe 'empty sets and non existing resources' do
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

    it "should not be able to retrieve metadata of the non exixting job" do
        get "/job/aaaa"
        last_response.status.should == 404
    end

    it "should not be able to delete a non existing job" do
        delete "/job/aaa"
        last_response.status.should == 404
    end


    it "should not be able to retrieve metadata of the non exixting app" do
        get "/appliance/aaaa"
        last_response.status.should == 404
    end

    it "should not be able to delete a non existing appliance" do
        delete "/appliance/aaa"
        last_response.status.should == 404
    end
end


describe 'creating an appliance' do
    it "should create a new appliance" do
        post '/appliance', File.read(EXAMPLES_PATH + '/appliance1.json')
        last_response.status.should == 201
        body = JSON.parse last_response.body

        $new_oid = body['_id']['$oid']
    end

    it "should be able to retrieve metadata of the new appliance" do
        get "/appliance/#{$new_oid}"
        last_response.status.should == 200
        body = JSON.parse last_response.body

        body['_id']['$oid'].should == $new_oid
        body['name'].should == 'CentOS'
        body['status'].should == 'init'
        body['creation_time'].should <= Time.now.to_i
    end

    it "appliance list should contain 1 element" do
        get "/appliance"
        body = JSON.parse last_response.body
        body.size.should eql(1)
        body[0]['name'].should == 'CentOS'
        body[0]['status'].should == 'init'
        body[0]['creation_time'].should <= Time.now.to_i
    end

    it "job list should contain 1 element" do
        get "/job"
        body = JSON.parse last_response.body
        body.size.should eql(1)
        body[0]['name'].should == 'upload'
        body[0]['status'].should == 'pending'
        body[0]['appliance_id'].should == $new_oid
        body[0]['worker_host'].should == nil
        body[0]['creation_time'].should <= Time.now.to_i
    end
end

describe 'creating a job' do
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
        body['worker_host'].should == nil
        body['creation_time'].should <= Time.now.to_i
    end

    it "job list should contain 2 element" do
        get "/job"

        body = JSON.parse last_response.body
        body.size.should eql(2)
        body[0]['name'].should == 'upload'
        body[0]['status'].should == 'pending'
        body[0]['appliance_id'].should == $new_oid
        body[0]['worker_host'].should == nil
        body[0]['creation_time'].should <= Time.now.to_i
        body[1]['_id']['$oid'].should == $new_job_oid
        body[1]['name'].should == 'convert'
        body[1]['status'].should == 'pending'
        body[1]['worker_host'].should == nil
        body[1]['creation_time'].should <= Time.now.to_i
    end
end

describe 'getting the next job from a worker' do
    it "should get a pending job" do
        get "/worker/firstworker/nextjob"
        last_response.status.should == 200

        body = JSON.parse last_response.body
        body['name'].should == 'upload'
        body['status'].should == 'in-progress'
        body['appliance_id'].should == $new_oid
        body['worker_host'].should == 'firstworker'
        body['creation_time'].should <= Time.now.to_i
        body['start_time'].should >= body['creation_time']
    end

    it "the appliance should be in uploading state" do
        get "/appliance/#{$new_oid}"
        last_response.status.should == 200

        body = JSON.parse last_response.body
        body['_id']['$oid'].should == $new_oid
        body['name'].should == 'CentOS'
        body['status'].should == 'downloading'
        body['creation_time'].should <= Time.now.to_i
    end

    it "should not be able to get more pending jobs, since there is only one" <<
            "app and there is already a job in-progress" do
        get "/worker/firstworker/nextjob"
        last_response.status.should == 404

        body = JSON.parse last_response.body
    end

    it "job list should contain 2 elements, one of them in-progress" do
        get "/job"

        body = JSON.parse last_response.body
        body.size.should eql(2)
        body[0]['name'].should == 'upload'
        body[0]['status'].should == 'in-progress'
        body[0]['appliance_id'].should == $new_oid
        body[0]['worker_host'].should == 'firstworker'
        body[0]['creation_time'].should <= Time.now.to_i
        body[0]['start_time'].should >= body[0]['creation_time']
        body[1]['_id']['$oid'].should == $new_job_oid
        body[1]['name'].should == 'convert'
        body[1]['status'].should == 'pending'
        body[1]['worker_host'].should == nil
        body[1]['creation_time'].should <= Time.now.to_i
        body[1]['start_time'].should == nil
    end
end

#describe 'deleting a job' do
#    # TODO delete should not be available only cancel
#    it "should delete the given job" do
#        delete "/job/#{$new_job_oid}"
#        last_response.status.should == 200
#
#        get "/job"
#
#        body = JSON.parse last_response.body
#
#        body.size.should eql(1)
#    end
#end

describe 'deleting an appliance' do
    it "should delete the given appliance" do
        delete "/appliance/#{$new_oid}"
        last_response.status.should == 200
    end

    it "job list should contain 2 element, one cancelling and another deleted" do
        get "/job"

        body = JSON.parse last_response.body
        body.size.should eql(2)
        body[0]['name'].should == 'upload'
        body[0]['status'].should == 'cancelling'
        body[0]['appliance_id'].should == $new_oid
        body[0]['worker_host'].should == 'firstworker'
        body[0]['creation_time'].should <= Time.now.to_i
        body[1]['_id']['$oid'].should == $new_job_oid
        body[1]['name'].should == 'convert'
        body[1]['status'].should == 'deleted'
        body[1]['worker_host'].should == nil
        body[1]['creation_time'].should <= Time.now.to_i
    end

    it "appliance list should be empty" do
        get "/appliance"

        body = JSON.parse last_response.body
        body.size.should eql(0)
    end
end

end
