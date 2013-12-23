require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'pp'

describe 'AppConverter tests' do
    before(:all) do
        DB.drop_collection(AppConverter::AppCollection::COLLECTION_NAME)
        DB.drop_collection(AppConverter::JobCollection::COLLECTION_NAME)

        basic_authorize('default','default')
        post '/user', File.read(EXAMPLES_PATH + '/worker.json'), {'HTTP_ACCEPT' => 'application/json'}
    end

describe 'empty sets and non existing resources' do
    before(:each) do
        basic_authorize('default','default')
    end

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
        get "/appliance", {}, {'HTTP_ACCEPT' => 'application/json'}

        body = JSON.parse last_response.body
        puts body
        body['appliances'].size.should eql(0)
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
        get "/appliance/aaaa", {}, {'HTTP_ACCEPT' => 'application/json'}
        last_response.status.should == 404
    end

    it "should not be able to delete a non existing appliance" do
        delete "/appliance/aaa", {}, {'HTTP_ACCEPT' => 'application/json'}
        last_response.status.should == 404
    end
end


describe 'creating an appliance' do
    before(:each) do
        basic_authorize('default','default')
    end

    it "should create a new appliance" do
        post '/appliance', File.read(EXAMPLES_PATH + '/appliance1.json')
        last_response.status.should == 201
        body = JSON.parse last_response.body

        $new_oid = body['_id']['$oid']
    end

    it "should be able to retrieve metadata of the new appliance" do
        get "/appliance/#{$new_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}
        last_response.status.should == 200
        body = JSON.parse last_response.body

        body['_id']['$oid'].should == $new_oid
        body['name'].should == 'CentOS'
        body['status'].should == 'init'
        body['creation_time'].should <= Time.now.to_i
    end

    it "appliance list should contain 1 element" do
        get "/appliance", {}, {'HTTP_ACCEPT' => 'application/json'}
        body = JSON.parse last_response.body
        body['appliances'].size.should eql(1)
        body['appliances'][0]['name'].should == 'CentOS'
        body['appliances'][0]['status'].should == 'init'
        body['appliances'][0]['creation_time'].should <= Time.now.to_i
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
    before(:each) do
        basic_authorize('default','default')
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
    before(:each) do
        basic_authorize('default','default')
    end

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
        get "/appliance/#{$new_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}
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
    before(:each) do
        basic_authorize('default','default')
    end

    it "should delete the given appliance" do
        delete "/appliance/#{$new_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}
        last_response.status.should == 200
    end

    it "job list should contain 2 element, one cancelling and another cancelled" do
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
        body[1]['status'].should == 'cancelled'
        body[1]['worker_host'].should == nil
        body[1]['creation_time'].should <= Time.now.to_i
    end

    it "appliance list should be empty" do
        get "/appliance", {}, {'HTTP_ACCEPT' => 'application/json'}

        body = JSON.parse last_response.body
        body['appliances'].size.should eql(0)
    end
end

describe 'getting the associated jobs to be cancelled of a worker and callback cancel' do
    before(:each) do
        basic_authorize('default','default')
    end

    it "should ge the jobs in cancelling status" do
        basic_authorize('worker','worker')
        get '/worker/firstworker/job?status=cancelling'

        body = JSON.parse last_response.body
        body.size.should eql(1)
        $upload_job_id = body[0]['_id']['$oid']
        body[0]['name'].should == 'upload'
        body[0]['status'].should == 'cancelling'
        body[0]['appliance_id'].should == $new_oid
        body[0]['worker_host'].should == 'firstworker'
        body[0]['creation_time'].should <= Time.now.to_i
        body[0]['progress'].should == 0
    end

    it "send cancel callback" do
        basic_authorize('worker','worker')
        post "/worker/firstworker/job/#{$upload_job_id}/cancel"
        body =  last_response.status
        puts body

        get '/worker/firstworker/job?status=cancelling'

        body = JSON.parse last_response.body
        puts body
        body.size.should eql(0)
    end

    it "job list should contain 2 element in cancelled status" do
        get "/job"

        body = JSON.parse last_response.body
        body.size.should eql(2)
        body[0]['name'].should == 'upload'
        body[0]['status'].should == 'cancelled'
        body[0]['appliance_id'].should == $new_oid
        body[0]['worker_host'].should == 'firstworker'
        body[0]['creation_time'].should <= Time.now.to_i
        body[1]['_id']['$oid'].should == $new_job_oid
        body[1]['name'].should == 'convert'
        body[1]['status'].should == 'cancelled'
        body[1]['worker_host'].should == nil
        body[1]['creation_time'].should <= Time.now.to_i
    end
end

describe 'creating a second appliance and callback update and done' do
    before(:each) do
        basic_authorize('default','default')
    end

    it "should create a new appliance" do
        post '/appliance', File.read(EXAMPLES_PATH + '/appliance1.json')
        last_response.status.should == 201
        body = JSON.parse last_response.body

        $new_oid2 = body['_id']['$oid']
    end

    it "should be able to retrieve metadata of the new appliance" do
        get "/appliance/#{$new_oid2}", {}, {'HTTP_ACCEPT' => 'application/json'}
        last_response.status.should == 200
        body = JSON.parse last_response.body

        body['_id']['$oid'].should == $new_oid2
        body['name'].should == 'CentOS'
        body['status'].should == 'init'
        body['creation_time'].should <= Time.now.to_i
    end

    it "appliance list should contain 1 element" do
        get "/appliance", {}, {'HTTP_ACCEPT' => 'application/json'}
        body = JSON.parse last_response.body
        body['appliances'].size.should eql(1)
        body['appliances'][0]['name'].should == 'CentOS'
        body['appliances'][0]['status'].should == 'init'
        body['appliances'][0]['creation_time'].should <= Time.now.to_i
    end

    it "job list should contain 3 elements" do
        get "/job"
        body = JSON.parse last_response.body
        body.size.should eql(3)
        body[0]['name'].should == 'upload'
        body[0]['status'].should == 'cancelled'
        body[0]['appliance_id'].should == $new_oid
        body[0]['worker_host'].should == 'firstworker'
        body[0]['creation_time'].should <= Time.now.to_i
        body[1]['_id']['$oid'].should == $new_job_oid
        body[1]['name'].should == 'convert'
        body[1]['status'].should == 'cancelled'
        body[1]['worker_host'].should == nil
        body[1]['creation_time'].should <= Time.now.to_i
        body[2]['name'].should == 'upload'
        body[2]['status'].should == 'pending'
        body[2]['appliance_id'].should == $new_oid2
        body[2]['worker_host'].should == nil
        body[2]['creation_time'].should <= Time.now.to_i
    end

    it "should get a pending job" do
        basic_authorize('worker','worker')
        get "/worker/firstworker/nextjob"
        last_response.status.should == 200

        body = JSON.parse last_response.body
        $upload_job_id2 = body['_id']['$oid']
        body['name'].should == 'upload'
        body['status'].should == 'in-progress'
        body['appliance_id'].should == $new_oid2
        body['worker_host'].should == 'firstworker'
        body['creation_time'].should <= Time.now.to_i
        body['start_time'].should >= body['creation_time']
    end

    it "the appliance should be in downloading state" do
        get "/appliance/#{$new_oid2}", {}, {'HTTP_ACCEPT' => 'application/json'}
        last_response.status.should == 200
        body = JSON.parse last_response.body

        body['_id']['$oid'].should == $new_oid2
        body['name'].should == 'CentOS'
        body['status'].should == 'downloading'
        body['creation_time'].should <= Time.now.to_i
    end

    it "send update callback" do
        basic_authorize('worker','worker')
        job = {
            'job' => {
                'progress' => 50
            }
        }
        post "/worker/firstworker/job/#{$upload_job_id2}/update", job.to_json
    end

    it "the job should be in done state" do
        get "/job/#{$upload_job_id2}"

        body = JSON.parse last_response.body

        body['_id']['$oid'].should == $upload_job_id2
        body['name'].should == 'upload'
        body['status'].should == 'in-progress'
        body['progress'].should == 50
        body['worker_host'].should == 'firstworker'
        body['creation_time'].should <= Time.now.to_i
    end

    it "send done callback" do
        basic_authorize('worker','worker')
        post "/worker/firstworker/job/#{$upload_job_id2}/done"
    end

    it "the appliance should be in ready state" do
        get "/appliance/#{$new_oid2}", {}, {'HTTP_ACCEPT' => 'application/json'}
        last_response.status.should == 200
        body = JSON.parse last_response.body

        body['_id']['$oid'].should == $new_oid2
        body['name'].should == 'CentOS'
        body['status'].should == 'ready'
        body['creation_time'].should <= Time.now.to_i
    end

    it "the job should be in done state" do
        get "/job/#{$upload_job_id2}"

        body = JSON.parse last_response.body

        body['_id']['$oid'].should == $upload_job_id2
        body['name'].should == 'upload'
        body['status'].should == 'done'
        body['progress'].should == 100
        body['worker_host'].should == 'firstworker'
        body['creation_time'].should <= Time.now.to_i
    end
end


describe 'creating a second job for the second appliance and callback error' do
    before(:each) do
        basic_authorize('default','default')
    end

    it "should create a new job" do
        hash = JSON.parse(File.read(EXAMPLES_PATH + '/job1.json'))
        hash['appliance_id'] = $new_oid2

        post '/job', hash.to_json
        body = JSON.parse last_response.body

        $new_job_oid2 = body['_id']['$oid']
    end

    it "should be able to retrieve metadata of the new job" do
        get "/job/#{$new_job_oid2}"

        body = JSON.parse last_response.body

        body['_id']['$oid'].should == $new_job_oid2
        body['name'].should == 'convert'
        body['status'].should == 'pending'
        body['worker_host'].should == nil
        body['creation_time'].should <= Time.now.to_i
    end

    it "job list should contain 2 element" do
        get "/job"

        body = JSON.parse last_response.body
        body.size.should eql(4)
        body[0]['name'].should == 'upload'
        body[0]['status'].should == 'cancelled'
        body[0]['appliance_id'].should == $new_oid
        body[0]['worker_host'].should == 'firstworker'
        body[0]['creation_time'].should <= Time.now.to_i
        body[1]['_id']['$oid'].should == $new_job_oid
        body[1]['name'].should == 'convert'
        body[1]['status'].should == 'cancelled'
        body[1]['worker_host'].should == nil
        body[1]['creation_time'].should <= Time.now.to_i
        body[2]['name'].should == 'upload'
        body[2]['status'].should == 'done'
        body[2]['appliance_id'].should == $new_oid2
        body[2]['worker_host'].should == 'firstworker'
        body[2]['creation_time'].should <= Time.now.to_i
        body[3]['_id']['$oid'].should == $new_job_oid2
        body[3]['name'].should == 'convert'
        body[3]['status'].should == 'pending'
        body[3]['worker_host'].should == nil
        body[3]['creation_time'].should <= Time.now.to_i
    end

    it "should get a pending job" do
        basic_authorize('worker','worker')
        get "/worker/secondworker/nextjob"
        last_response.status.should == 200

        body = JSON.parse last_response.body
        body['name'].should == 'convert'
        body['status'].should == 'in-progress'
        body['appliance_id'].should == $new_oid2
        body['worker_host'].should == 'secondworker'
        body['creation_time'].should <= Time.now.to_i
        body['start_time'].should >= body['creation_time']
    end

    it "the appliance should be in downloading state" do
        get "/appliance/#{$new_oid2}", {}, {'HTTP_ACCEPT' => 'application/json'}
        last_response.status.should == 200
        body = JSON.parse last_response.body

        body['_id']['$oid'].should == $new_oid2
        body['name'].should == 'CentOS'
        body['status'].should == 'converting'
        body['creation_time'].should <= Time.now.to_i
    end

    it "send error callback" do
        basic_authorize('worker','worker')
        post "/worker/secondworker/job/#{$new_job_oid2}/error"
    end

    it "the appliance should be in ready state" do
        get "/appliance/#{$new_oid2}", {}, {'HTTP_ACCEPT' => 'application/json'}
        last_response.status.should == 200
        body = JSON.parse last_response.body

        body['_id']['$oid'].should == $new_oid2
        body['name'].should == 'CentOS'
        body['status'].should == 'ready'
        body['creation_time'].should <= Time.now.to_i
    end

    it "the job should be in done state" do
        get "/job/#{$new_job_oid2}"

        body = JSON.parse last_response.body

        body['_id']['$oid'].should == $new_job_oid2
        body['name'].should == 'convert'
        body['status'].should == 'error'
        body['worker_host'].should == 'secondworker'
        body['creation_time'].should <= Time.now.to_i
    end
end
end
