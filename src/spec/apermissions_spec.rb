require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'pp'
describe 'MarketPlace User tests' do
    before(:all) do
        AppMarket::DB.drop_collection(AppMarket::AppCollection::COLLECTION_NAME)
    end

    describe "admin" do
        before(:each) do
            basic_authorize('default','default')
        end

        it "should exist in the DB after bootstraping" do
            get "/user", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body

            body['users'].size.should eql(1)

            $first_oid = body['users'].first['_id']['$oid']

            body['users'].first['username'].should == 'default'
            body['users'].first['role'].should == 'admin'
        end

        it "should be able to retrieve his metadata" do
            get "/user/#{$first_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body

            body['_id']['$oid'].should == $first_oid
            body['username'].should == 'default'
            body['role'].should == 'admin'
        end

        it "should be able to create new users" do
            post '/user', File.read(EXAMPLES_PATH + '/user.json'), {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body

            $new_oid = body['_id']['$oid']
        end

        it "should be able to retrieve metadata of the new user" do
            get "/user/#{$new_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body

            body['_id']['$oid'].should == $new_oid
            body['username'].should == 'new_user'
            body['role'].should == 'user'
        end

        it "should be able to retrieve the list of users including the new one" do
            get "/user", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body

            body['users'].size.should eql(2)

            body['users'][0]['_id']['$oid'].should == $first_oid
            body['users'][0]['username'].should == 'default'
            body['users'][0]['role'].should == 'admin'

            body['users'][1]['_id']['$oid'].should == $new_oid
            body['users'][1]['username'].should == 'new_user'
            body['users'][1]['role'].should == 'user'
        end
    end

   describe "user" do
        before(:each) do
            basic_authorize('new_user','new_pass')
        end

        it "should not be able to retrieve the list of users" do
            get "/user", {}, {'HTTP_ACCEPT' => 'application/json'}

            last_response.status.should eql(401)
        end

        it "should not be able to retrieve his metadata" do
            get "/user/#{$first_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}

            last_response.status.should eql(401)
        end

        it "should not be able to create new users" do
            post '/user', File.read(EXAMPLES_PATH + '/user2.json'), {'HTTP_ACCEPT' => 'application/json'}
            last_response.status.should eql(201)
        end

        it "should not be able to list the users" do
            get "/user", {}, {'HTTP_ACCEPT' => 'application/json'}

            last_response.status.should eql(401)
        end
    end

   describe "anonymous (no basic_auth is provided)" do
        it "should not be able to retrieve the list of users" do
            get "/user", {}, {'HTTP_ACCEPT' => 'application/json'}

            last_response.status.should eql(401)
        end

        it "should not be able to retrieve his metadata" do
            get "/user/#{$first_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}

            last_response.status.should eql(401)
        end

        it "should not be able to create new users" do
            post '/user', File.read(EXAMPLES_PATH + '/user3.json'), {'HTTP_ACCEPT' => 'application/json'}

            last_response.status.should eql(201)
        end

        it "should not be able to list the users" do
            get "/user", {}, {'HTTP_ACCEPT' => 'application/json'}

            last_response.status.should eql(401)
        end
    end
end

describe 'MarketPlace Appliance tests' do
    describe "admin" do
        before(:each) do
            basic_authorize('default','default')
        end

        it "should be able to retrieve the list of appliances" do
            get "/appliance", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body

            body['appliances'].size.should eql(0)
        end

        it "should be able to create new appliances" do
            post '/appliance', File.read(EXAMPLES_PATH + '/appliance.json'), {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body

            $new_oid = body['_id']['$oid']
        end

        it "should be able to retrieve metadata of the new appliance" do
            get "/appliance/#{$new_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body


            body['_id']['$oid'].should == $new_oid
            body['name'].should == 'Ubuntu Server 12.04 LTS (Precise Pangolin)'
        end

        it "should be able to retrieve restricted fields url, vistis and downloads" do
            get "/appliance/#{$new_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body


            body['_id']['$oid'].should == $new_oid
            body['name'].should == 'Ubuntu Server 12.04 LTS (Precise Pangolin)'

            body['files'][0]['url'].should == 'http://appliances.opennebula.systems/Ubuntu-Server-12.04/ubuntu-server-12.04.img.bz2'

            body['downloads'].should == 0
        end

        it "should be able to retrieve the download link" do
            get "/appliance/#{$new_oid}/download", {}, {'HTTP_ACCEPT' => 'application/json'}

            last_response.status == 302
            last_response.headers['Location'] == "http://appliances.opennebula.systems/Ubuntu-Server-12.04/ubuntu-server-12.04.img.bz2"
        end

        it "should be able to retrieve updated restricted fields url, vistis and downloads" do
            get "/appliance/#{$new_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body


            body['_id']['$oid'].should == $new_oid
            body['name'].should == 'Ubuntu Server 12.04 LTS (Precise Pangolin)'

            body['files'][0]['url'].should == 'http://appliances.opennebula.systems/Ubuntu-Server-12.04/ubuntu-server-12.04.img.bz2'

            body['downloads'].should == 1
        end

        it "should be able to retrieve the list of appliances including the new one" do
            get "/appliance", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body

            body['appliances'].size.should eql(1)

            body['appliances'][0]['_id']['$oid'].should == $new_oid
            body['appliances'][0]['name'].should == 'Ubuntu Server 12.04 LTS (Precise Pangolin)'
        end
    end

   describe "user" do
        before(:each) do
            basic_authorize('new_user','new_pass')
        end

        it "should be able to retrieve the list of appliances" do
            get "/appliance", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body

            body['appliances'].size.should eql(1)

            body['appliances'][0]['_id']['$oid'].should == $new_oid
            body['appliances'][0]['name'].should == 'Ubuntu Server 12.04 LTS (Precise Pangolin)'
        end

        it "should be able to create new appliances" do
            post '/appliance', File.read(EXAMPLES_PATH + '/appliance2.json'), {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body
            $new_oid2 = body['_id']['$oid']
        end

        it "should be able to retrieve metadata of the new appliance" do
            get "/appliance/#{$new_oid2}", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body


            body['_id']['$oid'].should == $new_oid2
            body['name'].should == 'CentOS 6.2'
        end

        it "should not be able to retrieve restricted fields url, vistis and downloads" do
            get "/appliance/#{$new_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body


            body['_id']['$oid'].should == $new_oid
            body['name'].should == 'Ubuntu Server 12.04 LTS (Precise Pangolin)'

            body['files'][0]['url'].should == nil
            body['downloads'].should == 1
        end

        it "should be able to retrieve the download link" do
            get "/appliance/#{$new_oid}/download", {}, {'HTTP_ACCEPT' => 'application/json'}

            last_response.status == 302
            last_response.headers['Location'] == "http://appliances.opennebula.systems/Ubuntu-Server-12.04/ubuntu-server-12.04.img.bz2"
        end

        it "should be able to retrieve the list of appliances including the new one" do
            get "/appliance", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body

            body['appliances'].size.should eql(2)

            body['appliances'][0]['_id']['$oid'].should == $new_oid
            body['appliances'][0]['name'].should == 'Ubuntu Server 12.04 LTS (Precise Pangolin)'
            body['appliances'][1]['_id']['$oid'].should == $new_oid2
            body['appliances'][1]['name'].should == 'CentOS 6.2'
        end
    end

   describe "anonymous (no basic_auth is provided)" do
        it "should  be able to retrieve the list of appliances" do
            get "/appliance", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body

            body['appliances'].size.should eql(2)

            body['appliances'][0]['_id']['$oid'].should == $new_oid
            body['appliances'][0]['name'].should == 'Ubuntu Server 12.04 LTS (Precise Pangolin)'
        end

        it "should be able to retrieve metadata of the  appliance" do
            get "/appliance/#{$new_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body

            body['_id']['$oid'].should == $new_oid
            body['name'].should == 'Ubuntu Server 12.04 LTS (Precise Pangolin)'
        end

        it "should not be able to retrieve restricted fields url, vistis and downloads" do
            get "/appliance/#{$new_oid}", {}, {'HTTP_ACCEPT' => 'application/json'}

            body = JSON.parse last_response.body


            body['_id']['$oid'].should == $new_oid
            body['name'].should == 'Ubuntu Server 12.04 LTS (Precise Pangolin)'

            body['files'][0]['url'].should == nil
            body['downloads'].should == 2
        end

        it "should be able to retrieve the download link" do
            get "/appliance/#{$new_oid}/download", {}, {'HTTP_ACCEPT' => 'application/json'}

            last_response.status == 302
            last_response.headers['Location'] == "http://appliances.opennebula.systems/Ubuntu-Server-12.04/ubuntu-server-12.04.img.bz2"
        end

        it "should not be able to create new appliances" do
            post '/appliance', File.read(EXAMPLES_PATH + '/appliance.json'), {'HTTP_ACCEPT' => 'application/json'}

            last_response.status.should eql(401)
        end
    end
end
