# Live Test

The live test of allyabase will aggregate public keys from anyone who has ever worked on or been engaged with any Planet Nine software, and would like to participate.
We will perform at least one transaction via [MAGIC][magic] that splits payment between whatever keys have been aggregated. 

## How to join the test:

### Developers

* Grab the [Sessionless][sessionless] implementation of your choice, or the [addie-js][addie-js] node module, or Kal's [key generator](https://github.com/Daniel-J-Mason/sessionless-toolkit/blob/main/.github/workflows/all-platform-release.yml)

* Generate a keypair or use addie.createUser (note, you'll need to change the baseURL of addie to `https://livetest.addie.allyabase.com`)

* Follow the documentation for [addie][addie] to register at https://livetest.addie.allyabase.com, and then create an account token for yourself for the processor stripe (You can see an example of this API call in the addie test in the allyabase repo, or in `server.js` is this directory)

* Share your addie public key, stripe account id, and addie uuid with planetnineisaspaceship aka Zach

(if you don't have time for all this you can use the website below too, but it'd be great to test the docs a bit). 

### Non-developers

* Go to https://livetest.addie.allyabase.com/bar, fill in the three fields, click the button, wait a bit, and then share the public key that appears with planetnineisaspaceship aka Zach.

## Where and when

The test will take place on Twitch so that people can watch it wherever they are. 
I do not have a time yet, but it should be before the end of the month.

[sessionless]: https://www.github.com/freyja-love-and-magic/sessionless
[addie-js]: https://www.npmjs.com/package/addie-js
