Vokab::Item:: API
==================

Public attributes
-----------------

All attributes have public get/set accessors. However, I see no reason why any
class should ever access attributes other than its own.

Methods
-------

* `->new()`: instantiate an object with no attributes set. Can be called with
  attributes wherever appropriate.
* `->display_all( $window )`: add row(s) to the `$window` containing entries
  querying a user to input values for the item's attributes.
* `->set_all()`: Set the attributes after they're submitted.
* `->write()`: write this class's attributes to the corresponding table in the
  DB.  Throws an exception if the insert fails
* `->display_quiz()`: returns a Gtk object asking the user for a Eng-De
  translation. Unlike all methods above, this overrides its ancestors
* `->set_quiz( $result_list )`: Increment the number of tests and (if
  appropriate) the number of successes. If the result was incorrect, return a
  Gtk object with a failure message or the correct answer. As with
  `query_display()`, this overrides its ancestors
  *NB*: use an "after" trigger to recompute the score
  *FIXME*: return a bool; define the on-failure Gtk object in an attribute

Except in methods `query_display()` and `validate_query_result()`, the root and
intermediate classes should call `inner()` at an appropriate point; non-root
classes should extend the parent's definition with `augment`.
