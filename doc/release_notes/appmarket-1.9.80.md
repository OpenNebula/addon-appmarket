AppMarket 2.0 Beta (1.9.80)
===========================

February 3rd, 2014. The OpenNebula team is pleased to announce a beta release of AppMarket 2.0. This release includes important features that are a direct result of feedback from production deployments.

This release extends the AppMarket functionality by adding a new set of features that enables the management and processing of OVA files. A new component *AppMarket Worker* is introduced, which handles the OVA package treatment (download, unpack, OVF parsing) and image format conversion. This release also features a new API and a new AppMarket interface via Sunstone.

What's New in AppMarket 2.0 Beta
--------------------------------

In the following list you can check the highlights of AppMarket 2.0 Beta:

### AppMarket

* **Multi-image Appliances**: AppMarket Appliances can now have multiple disks, which creates new possibilities to upload and register more complex and feature complete Appliances.
* **Sunstone Import**: users will be able to import registered Appliances to OpenNebula via Sunstone by using pre-filled Image and Template creation forms.
* **Sunstone Views**: two new Sunstone views: an AppMarket *admin* view, that allows full control of the AppMarket, and a *user* view, that allows end users to import registered appliances.

These new features will be only available interacting with AppMarket from an OpenNebula 4.6 deployment.

### AppMarket Worker

A new horizontally-scalable component that subscribes to the AppMarket and executes jobs. It enhances the AppMarket functionality by adding:

* **OVA processing**: If a URL to an OVA package is supplied, the AppMarket will be able completely process it and integrate it to its repository. This involves: downloading and unpacking of the OVA package, parsing of the OVF file and creating a corresponding OpenNebula template.
* **Format conversion**: appliances registered in a specific format, can be converted to a new format.
* **Extensibility**: All the operations described above are implemented within the framework of an extensible driver engine, which allows further customization and integration by the administrators.

Acknowledgements
----------------

The new features introduced in the AppMarket 2.0 were funded by [Produban](http://www.produban.com/) in the context of the Fund a Feature Program.
