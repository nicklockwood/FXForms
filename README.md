Purpose
--------------

FXForms is an Objective-C library for easily creating table-based forms on iOS. It is ideal for settings pages, or user data entry tasks.

Unlike other solutions, FXForms works directly with strongly-typed data models that you supply (instead of dictionaries or complicated dataSource protocols), and infers as much information as possible from your models using introspection, to avoid the need for tedious duplication of type information.


Supported iOS & SDK Versions
-----------------------------

* Supported build target - iOS 7.0 (Xcode 5.0)
* Earliest supported deployment target - iOS 5.0
* Earliest compatible deployment target - iOS 4.3

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this iOS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

FXForms requires ARC. If you wish to use FXForms in a non-ARC project, just add the -fobjc-arc compiler flag to the FXForms.m class. To do this, go to the Build Phases tab in your target settings, open the Compile Sources group, double-click FXForms.m in the list and type -fobjc-arc into the popover.

If you wish to convert your whole project to ARC, comment out the #error line in FXForms.m, then run the Edit > Refactor > Convert to Objective-C ARC... tool in Xcode and make sure all files that you wish to use ARC for (including FXForms.m) are checked.


Usage
---------

FXForms is currently in beta, and the API is still in flux. Once it has been locked down, this documentation will be extended. In the meantime, look at the example project for a demo of how to integrate FXForms into your project.


Release Notes
--------------

Version 1.0 beta

- Initial release