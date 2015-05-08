# Transair

A translation management system. Transair works by synchronizing a local database of translations with a remote service. Developers add the master strings to a local file and runs `transair sync`. New and updated master strings are uploaded to the service and made available for translation. Once the strings have been translated, `transair sync` will download and store the translations.

Both master and translation strings are supposed to be stored in version control, making deployment simple and reliable.

###### Example usage

```
# Add master strings to `masters.yml`
$ cat masters.yml
foo.bar.hello: "Hello, World!"
foo.bar.goodbye: "Goodbye, Cruel World!"

# New and updated master strings will be uploaded
$ transair sync --url http://transair.example.com
Syncing key foo.bar.hello...
Key foo.bar.hello not found, uploading...
Uploaded key foo.bar.hello
Syncing key foo.bar.goodbye...
Key foo.bar.goodbye not found, uploading...
Uploaded key foo.bar.goodbye

$ transair sync --url http://transair.example.com
Syncing key foo.bar.hello...
Key foo.bar.hello found, storing 0 translations...
Syncing key foo.bar.goodbye...
Key foo.bar.goodbye found, storing 0 translations...

# Add translations using the API
$ transair translate --url http://transair.example.com --key foo.bar.hello --version 0a0a9f2a6772 --locale da --translation "Hejsa"

# Translations are automatically downloaded when syncing
$ transair sync --url http://transair.example.com
Syncing key foo.bar.hello...
Key foo.bar.hello found, storing 1 translations...
Syncing key foo.bar.goodbye...
Key foo.bar.goodbye found, storing 0 translations...

$ cat translations/da.yml
---
foo.bar.hello: Hejsa
```
