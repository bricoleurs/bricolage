User interface tests for Bricolage


Running the tests

N.B.: TESTS WILL MODIFY DATA!

1) Set the BRICOLAGE_SERVER (full URL, beginning with http,
shouldn't have a trailing slash), BRICOLAGE_USERNAME, and
BRICOLAGE_PASSWORD environment variables.
2) Make sure Bricolage is running at BRICOLAGE_SERVER.
3) To run all the tests, type `make uitest` from the base
Bricolage directory where 'Makefile' is. You can alternatively
run each test independently from within this directory (t/UI);
for example, `perl 000-testbase.t`.


About the tests

The tests use a module which is a thin subclass of
Test::WWW::Mechanize, which in turn is a subclass
of WWW::Mechanize with methods added for testing.
(XXX: I will change this to use Bric::Mech instead.)

I assume the language is set to en_us when checking for
page content. So a test might expect 'Workflow', which would
fail if the language was Russian. I wanted to keep the tests
as independent of anything as possible, which means not assuming
that the Bricolage library is installed on the machine from which
the tests are run, which in turn means not being able to find
localization strings. Maybe it's wrong to do this.

I've only run the tests on an empty Bricolage 1.8.3.

The tests are run in the order that t/UI/*.t lists them.
Currently I'm naming them all with 3-digit prefixes,
like 000-testbase.t. Tests starting with '0' are basic
tests. 100s will probably be ADMIN->SYSTEM, 200s and
300s will probably be ADMIN->PUBLISHING, 400s will
probably be ADMIN->DISTRIBUTION, 800s will probably be
'My Workspace'. 500s are media-related, 600s are
story-related, 700s are template-related. 900s will
probably be used to clean up things that were created.
For example, if I test adding a Destination (400s),
I'd use that for testing story publishing (600s), then in
the end (900s) test deleting the destination.

According to `perldoc Test::More`, using 'no_plan', as I do,
requires an upgrade of Test::Harness. So do that. (See the
top of 000-testbase.t.)
