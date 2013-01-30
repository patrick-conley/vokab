Vokab::Item:: API
==================

Public attributes
-----------------

All attributes have public get/set accessors. However, I see no reason why any
class should ever access attributes other than its own.

Methods
-------

* `new()`: instantiate an object with no attributes set. Can be called with
  attributes wherever appropriate.
* `Vokab::Item->read( id => $id, type => $type )`, where `$type` is the name of
  a leaf subclass of `Vokab::Item`: Return a new object of subclass `$type`
  _with all attributes set_.
  * if `$type` is not provided, two DB accesses must be made
  * neither argument is required if these attributes have already been set.
  Note that this behaviour means one Vokab::Item object can be created at
  program launch and used repeatedly to instantiate objects for each item
  needed.
* `input_display()`: returns a Gtk object (VBox, HBox, etc., as appropriate)
  querying a user to input data for an item
  * *TODO*: work out how this works out
* `write()`: write this class's attributes to the corresponding table in the DB.
  Throws an exception if the insert fails
* `query_display()`: returns a Gtk object asking the user for a Eng-De
  translation. Unlike all methods above, this overrides its ancestors
* `validate_query_result( $result_list )`: Increment the number of tests and (if
  appropriate) the number of successes. If the result was incorrect, return a
  Gtk object with a failure message or the correct answer. As with
  `query_display()`, this overrides its ancestors
  *NB*: use an "after" trigger to recompute the score
  *FIXME*: return a bool; define the on-failure Gtk object in an attribute

Except in methods `query_display()` and `validate_query_result()`, the root and
intermediate classes should call `inner()` at an appropriate point; non-root
classes should extend the parent's definition with `augment`.
