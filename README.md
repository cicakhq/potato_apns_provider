# Compile and run

Compile the code:

```
mix deps.get
mix compile
```

Then, run iex:

```
iex -S mix
```

To start the service, run the following command from the commandline:

```
APNS_Listener.start_link
```

# CouchDB

The file `foo.ex` contains some test code to talk to CouchDB. The
CouchDB library returns the raw JSON strings. The example uses Poison
to encode and decode the JSON structures.
