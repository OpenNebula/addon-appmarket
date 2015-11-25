# AppMarket

## Description

AppMarket allows you to build your own internal marketplace service. Your OpenNebula users will be able to import the appliances from your internal AppMarket service to their OpenNebula instance through a new Sunstone tab called AppMarket, reducing the time needed to jumpstart a OpenNebula deployment and also making it possible to quickly incorporate new services to the cloud offering.

An OpenNebula Virtual Appliance is a pre-built software solution, consisting of a set of pre-configured virtual machine images and a template, ready-to-run on an OpenNebula cloud. The Marketplace contains metadata that defines the Virtual Appliance but not the appliance files themselves. The metadata includes the links to download the appliance files from third-party servers.

After deploying the AppMarket server, users will be able to access the AppMarket functionality through its GUI, pointing the web browser to the url where the server is running; or through the CLI, using the appmarket* commands.

The [OpenNebula Marketplace](http://marketplace.opennebula.systems/appliance) is an example of an AppMarket deployment currently running and publicly accessible for the OpenNebula community, every OpenNebula installation is ready to interact with this marketplace, through the Marketplace tab in Sunstone.

Please consider that, although AppMArket is widely used by the OpenNebula users, this software has not gone through the same rigorous testing process as the main OpenNebula distribution.

![market1306](doc/images/list_appliance_from_sunstone.png)

## Authors

* Leader: Daniel Molina Aranda dmolina@opennebula.org
* Jaime Melis jmelis@opennebula.org

## Features

* Build your own marketplace
* Share virtual appliances across several OpenNebula instances
* Distribute internally developed virtual appliances
* Provide appliances from a catalog and portal
* Tight integration with OpenNebula
* Appliances can define multiple files and an OpenNebula template
* Appliances can be grouped in catalogs

## Releases

### AppMarket

* [Installation & Configuration](doc/installation_and_configuration.md)
* [Usage](doc/usage.md)
* [Release Notes](doc/release_notes/appmarket-2.1.0.md)

### All Releases

|      Version      |        Date          |                               Release Notes                               |
| ----------------- | -------------------- | ------------------------------------------------------------------------- |
| 2.1.0             | November, 2015       | [Release Notes 2.1.0](https://github.com/OpenNebula/addon-appmarket/releases/tag/release-2.1.0)               |
| 2.0.3             | November 19th, 2014  | [Release Notes 2.0.3](doc/release_notes/appmarket-2.0.3.md)               |
| 2.0.2             | September 18th, 2014 | [Release Notes 2.0.2](doc/release_notes/appmarket-2.0.2.md)               |
| 2.0.1             | May 22nd, 2014       | [Release Notes 2.0.1](doc/release_notes/appmarket-2.0.1.md)               |
| 2.0.0             | May 13th, 2014       | [Release Notes 2.0.0](doc/release_notes/appmarket-2.0.0.md)               |
| 1.9.90 (2.0 RC2)  | April 29th, 2014     | [Incremental Release Notes 1.9.90](doc/release_notes/appmarket-1.9.90.md) |
| 1.9.85 (2.0 RC)   | April 22nd, 2014     | [Incremental Release Notes 1.9.85](doc/release_notes/appmarket-1.9.85.md) |
| 1.9.80 (2.0 Beta) | February 3rd, 2014   | [Release Notes 1.9.80](doc/release_notes/appmarket-1.9.80.md)             |

## Compatibility

This add-on is compatible with:

| AppMarket Version | OpenNebula Version |
| ----------------- | ------------------ |
| 2.1.0             | 4.14.2             |
| <= 2.0.3          | 4.10, 4.12         |

## Development

To contribute bug patches or new features, you can use the github Pull Request model. It is assumed that code and documentation are contributed under the Apache License 2.0.

More info:
* [How to Contribute](http://opennebula.org/software:add-ons#how_to_contribute_to_an_existing_add-on)
* Support: [OpenNebula forum](https://forum.opennebula.org/c/support)
* Development: [OpenNebula forum](https://forum.opennebula.org/c/development)
* Issues Tracking: Github issues
