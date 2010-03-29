# TODO

* handle condition where user has revoked access but still has cookie'd keys-- watch for 401's and redirect back to /login for new keys
* reduce geocoder calls. don't call IPGeocode.new in Checkins, keep data around from city call.
* test suite

* bundler doesn't seem to want to work with passenger
* ajax reloader
* test IP address issues in different conditions