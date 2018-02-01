# json-api
It's often that an Elm application needs to communicate with a JSON API. The HTTP requests and list operations involved in this communication can tend to be very similar, and writing the resulting boilerplate code can be time-consuming.

**json-api** provides two modules of simple helper functions:

- `Request` - for constructing URLS, encoding resources as JSON, and sending HTTP requests.
- `Response` - for handling responses, decoding resources, and updating a `List` of resources. 

## Example
See an example application in the [examples](https://github.com/duncanmalashock/json-api/blob/master/examples/Main.elm) directory of this repo.

### To see it in the browser:
Run the following from the `/examples` directory of this project:
```
elm-make Main.elm
```
Then open `index.html` in a browser.
