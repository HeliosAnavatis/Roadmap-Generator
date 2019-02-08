# Roadmap-Generator
Perl script to generate roadmaps.  The script takes a CSV file containing the events and churns out a GraphML file which can then be read with a GraphML viewer.  You can then turn it into a PDF, or do whatever you want with it.

## Prerequisites
* A Perl 5 distribution.  I use [Strawberry Perl](http://strawberryperl.com/) when working on Windows
* The following CPAN modules installed:
  - [yEd::Document](https://metacpan.org/release/yEd-Document)
  - [List::MoreUtils](https://metacpan.org/pod/List::MoreUtils)
  - [Text::Wrap](https://metacpan.org/pod/Text::Wrap)
  - [Tree::Simple](https://metacpan.org/pod/Tree::Simple)
  - [Tree::Simple::VisitorFactory](https://metacpan.org/release/Tree-Simple-VisitorFactory)
  - [Date::Format](https://metacpan.org/pod/Date::Format)
  - Any prerequisites for the above modules
 * A valid roadmap source CSV file.  Note that the script does not do any error checking.  It is up to you to sort out your data. GIGO.
 * A valid config.txt file. Read the included config.txt to see what's configurable.
 * A copy of [yEd](https://www.yworks.com/products/yed) or any other GraphML viewer/editor
 
 ## Input File Format
 The CSV file requires the following columns (in order):
 * *Event ID* - a unique ID number for this event.
 * *Name* - A short descriptive name for this event.  No fixed upper bound, but try to keep it below about 30 characters for the best layout.
 * *Component* - Names for groups of events which form major components.  If you're doing an infrastructure roadmap, you might have components including "Network", "Storage", or "Compute" but the names really are up to you.
 * *Type* - one of *Deliverable*, *Function*, *Capability*, *Decision* or *Milestone*
 * *Prerequisites* - a colon-separated list of *Event ID*s which precede this event.
 * *Notes* - Can be anything you like; it isn't used in this script.
 
 The first line of the input file is always assumed to be a header line and is *always* ignored. You have been warned.
 
 ## To Do
 * Add a legend for the event type shapes
 * Add optional prerequisites
 * Improve event layout
 * Improve line routing
 * Remove my shoddy commented out debugging code
