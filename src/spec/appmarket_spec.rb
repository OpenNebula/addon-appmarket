require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'pp'

describe 'AppMarket tests' do
    before(:all) do
        AppMarket::DB.drop_collection(AppMarket::AppCollection::COLLECTION_NAME)

        basic_authorize('default','default')
        post '/user', File.read(EXAMPLES_PATH + '/worker.json'), {'HTTP_ACCEPT' => 'application/json'}
    end

describe 'empty sets and non existing resources' do
    before(:each) do
        basic_authorize('default','default')
    end

    it "appliance list should be empty" do
        get "/appliance", {}, {'HTTP_ACCEPT' => 'application/json'}

        body = JSON.parse last_response.body
        body['appliances'].size.should eql(0)
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
        body['creation_time'].should <= Time.now.to_i
    end

    it "appliance list should contain 1 element" do
        get "/appliance", {}, {'HTTP_ACCEPT' => 'application/json'}
        body = JSON.parse last_response.body
        body['appliances'].size.should eql(1)
        body['appliances'][0]['name'].should == 'CentOS'
        body['appliances'][0]['creation_time'].should <= Time.now.to_i
    end
end

describe 'deleting an appliance' do
    before(:each) do
        basic_authorize('default','default')
    end

    it "should delete the given appliance" do
        delete "/appliance/#{$new_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}
        last_response.status.should == 204
    end

    it "appliance list should be empty" do
        get "/appliance", {}, {'HTTP_ACCEPT' => 'application/json'}

        body = JSON.parse last_response.body
        body['appliances'].size.should eql(0)
    end
end
end
