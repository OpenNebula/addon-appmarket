AppMarket 2.0.3
===============

November 19th, 2014. The OpenNebula team is pleased to announce the release maintenance of AppMarket 2.0.2. This is a maintenance release that solves issues reported by the community.

This release is part of the AppMarket 2.0.x series, which extends the AppMarket functionality by adding a new set of features that enables the management and processing of OVA files. A new component *AppMarket Worker* is introduced, which handles the OVA package treatment (download, unpack, OVF parsing) and image format conversion. This release also features a new API, a new [simplified import dialog](../usage.md), a new AppMarket interface via Sunstone, and handles VMware and VirtualBox OVAs.

What's New in the AppMarket 2.0.x Series
-----------------------------------------

In the following list you can check the highlights of AppMarket 2.0.x:

### AppMarket

* **Multi-image Appliances**: AppMarket Appliances can now have multiple disks, which creates new possibilities to upload and register more complex and feature complete Appliances.
* **Sunstone Import**: users will be able to import registered Appliances to OpenNebula via Sunstone by using pre-filled Image and Template creation forms.
* **Sunstone Views**: two new Sunstone views: an AppMarket *admin* view, that allows full control of the AppMarket, and a *user* view, that allows end users to import registered appliances.
* New **simplified import dialog**.

### AppMarket Worker

A new horizontally-scalable component that subscribes to the AppMarket and executes jobs. It enhances the AppMarket functionality by adding:

* **OVA processing**: If a URL to an OVA package is supplied, the AppMarket will be able completely process it and integrate it to its repository. This involves: downloading and unpacking of the OVA package, parsing of the OVF file and creating a corresponding OpenNebula template. This component supports VMware and VirtualBox OVFs.
* **Format conversion**: appliances registered in a specific format, can be converted to a new format.
* **Extensibility**: All the operations described above are implemented within the framework of an extensible driver engine, which allows further customization and integration by the administrators.

Resolved Issues
---------------

This is a list of issues solved in AppMarket 2.0.3

- Feature: Add opennebula_version to the creation form
- Feature: Add dev_prefix and driver to the creation form
- Feature: Fill opennebula_template input in update form
- Bug: Remove original appliance not the newly converted one
- Bug: Display first level app attributes for hypervisor, os-arch and format in the Sunstone tables
- Bug: Remove testing gems from Gemfile
- Bug: Delete job is now parsing correctly the CONF file
- Bug: Handle properly urls that contain error prone chars like [], etc...
- Bug: Remove csrftoken from the job creation method
- Bug: Mime-types gem latest version can't be installed in ruby 1.8.7
- Bug: Fix input layout when the import fails

Acknowledgements
----------------

The new features introduced in the AppMarket 2.0.x series were funded by [Produban](http://www.produban.com/) in the context of the Fund a Feature Program.
