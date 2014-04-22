AppMarket Worker Installation and Configuration
===============================================

Introduction
------------

This component enables the [OVA](http://en.wikipedia.org/wiki/Open_Virtualization_Format) package processing capabilities of the AppMarket, which include:

* OVA package download
* Unpack
* OVF parsing and generation of the corresponding OpenNebula template
* Format conversion of the disk images included in the OVA package

This extension is not strictly required. However if installed it will provide the AppMarket with the extra functionality described above.

Requirements
------------

The AppMarket worker requires:

* A reachable AppMarket
* Ruby and RubyGems installed.
* A web server to expose the uploaded/converted files via http
* Qemu-img for conversions
* A filesystem with enough disk space to store the images and the temporary data generated during OVA package processing. This space should be calculated as twice the size of the unpackage OVA package.

If there is more than one worker the filesystem where the images are stored must be shared across all the hosts. It is recommended to use a high-performance NFS, Gluster or Ceph.

Install AppMarket Worker
------------------------

AppMarket packages can be downloaded from the [OpenNebula Downloads](http://downloads.opennebula.org/packages/appmarket-1.9.85/) page in two formats:

* rpm package
* deb package

The rpm and deb packages can be installed with ''dpkg'' and ''rpm'' respectively:

    # Debian/Ubuntu
    sudo dpkg -i appmarket-worker_1.9.85.deb

    # CentOS/openSUSE
    sudo rpm -i appmarket-worker_1.9.85.rpm

To install from source code you can run the following command:

    ./install.sh -h

The following commands are necessary in any of the previous cases to install the required gems

* bundler. To install it you can issue as root:

        gem install bundler

* Required gems. To install the gems needed by AppMarket do this as root:

        cd /usr/lib/one/ruby/appconverter/
        bundle install

        gem 'json'
        gem 'nokogiri'
        gem 'open4'

Configure AppMarket Worker
--------------------------

The AppMarket configuration file can be found at */etc/one/appconverter-worker.conf*. It uses YAML syntax and the following parameters can be configured in this file

### AppMarket Endpoint

The AppMarket Worker must connect to a running AppMarket. This url has to be configured here:

    # Url of the AppMarket
    :appmarket_url: http://localhost:6242

### AppMarket Worker User

The AppMarket Worker must authenticate with the AppMarket. To do so the administrator must configure these two options:

    # Username and password for the user that interacts with the AppMarket.
    # It is recommended to use an account that has the 'worker' role.
    :username: worker
    :password: worker

Additionally, a name to identify the particular worker node must be specified here:

    # Identifier of the worker
    :worker_name: imtheworker

In order to work, the user must exist in the AppMarket. To add a user to the AppMarket, first create a json file for the user **worker.json**:

    {
        "username":     "worker",
        "password":     "worker",
        "organization": "worker",
        "first_name":   "new_user",
        "last_name":    "new_user",
        "website":      "new_user",
        "email":        "new_user",
        "status":       "enabled",
        "role":         "worker"
    }

The user can now be added to the AppMarket:

    appmarket-user create -u <admin_user> -p <admin_pass> worker.json

### Simultaneous Jobs

Each worker is limited to a maximum number of running simultaneous jobs. To increase or decrease the default number (5) change to following in the configuration:

    # Maximum number of simultaneous jobs
    :max_jobs: 5

### Poll Interval

The interval at which the AppMarket Worker polls the AppMarket for new jobs:

    # Poll interval in seconds
    :interval: 5

### Paths

There are several paths that must be configured in the AppMarket worker:

    # Path of the local repository to store imported files. This repository
    # should be shared across all the worker hosts, accessible by a web server
    :repo: /var/tmp/appmarket-repo

    # Base uri of the imported files. This address should be served by a
    # dedicated web server or a node balancer.
    :base_uri: http://localhost

    # Temporary directory were files are imported and treated. This directory
    # should not be accessible via a web server.
    :temp_dir: /var/tmp/appmarket-tempdir

### Debugging

Enable debugging by activating:

    # Enable debugging logs (generated in /var/tmp)
    :debug: true

Web Service
-----------

Images will be stored in the path pointed by the the ''repo'' parameter of the configuration file. This path should be shared across all the nodes and exported by a web server. This web server can be configured using any technology: ''Apache'', ''Lighttpd'', ''Nginx'', etc. The configuration required is just a plain ''DocumentRoot'' pointing to the repo path (default ''/var/tmp/appmarket-repo'').

The bare minimum for debugging purposes would be to launch an ad-hoc Python web server in that directory

    $ cd /var/tmp/appmarket-repo
    $ sudo python2 -m SimpleHTTPServer 80

However it is recommended to use one of the classical web servers mentioned above for production deployments.

Start the Worker
----------------

To start and stop the server, use the ''appconverter-worker start/stop'' command:

    appconverter-worker start
    # appconverter-worker started

Inside */var/log/one/* you will find new log files for the server.

    /var/log/one/appconverter-worker.error
    /var/log/one/appconverter-worker.log

Scalability
-----------

The AppMarket Worker is designed to be horizontally scalable. Add more working nodes in the same way a single worker node is installed. The new nodes will also poll and distribute the jobs.

Customize
---------

There are 3 customizable scripts:

* **/usr/lib/one/ruby/appconverter/drivers/upload**: Downloads, unpacks and parses OVA packages. It can be extended to support additional appliance package formats.
* **/usr/lib/one/ruby/appconverter/drivers/convert**: Converts files of an appliance from one format to another. Currently these conversions are defined:

        CMDS = {
            "vmdk" => {
                "qcow2" => {
                    "cmd" => lambda {|s,t|
                        "qemu-img convert -O qcow2 #{s} #{t}"
                    }
                },
                "raw" => {
                    "cmd" => lambda {|s,t|
                        "qemu-img convert -O raw #{s} #{t}"
                    }
                }
            },
            "qcow2" => {
                "vmdk" => {
                    "cmd" => lambda {|s,t|
                        "qemu-img convert -O vmdk #{s} #{t}"
                    }
                },
                "raw" => {
                    "cmd" => lambda {|s,t|
                        "qemu-img convert -O raw #{s} #{t}"
                    }
                }
            },
            "raw" => {
                "qcow2" => {
                    "cmd" => lambda {|s,t|
                        "qemu-img convert -O qcow2 #{s} #{t}"
                    }
                },
                "vmdk" => {
                    "cmd" => lambda {|s,t|
                        "qemu-img convert -O vmdk #{s} #{t}"
                    }
                }
            }
        }

* **/usr/lib/one/ruby/appconverter/drivers/delete**: Deletes all the disk images of an appliance when an appliance is removed.

