# On distributed systems

Magic: the Gathering, a collectible card game I've played off and on for three decades, recently revealed a new mechanic called "behold." 
Doing so led players to resurrect a 2500 year old meme of Plato defining man as a featherless biped, and a student named Diogenes then plucking a chicken, and exclaiming, "behold a man!"

![The friends meme of Phoebe and Joey going back and forth only its Plato and Diogenes, and in the last panel, Diogenes has a plucked chicken](./behold.jpg)

Rather than learning the lesson that reductive definitions of complex things will always leave much to be desired, humanity has instead spent quite a lot of time debating the specifics of what things _are_. 
The branch of philosophy that deals with this is called Metaphysics. 
And today I'd like to take you on a pleasant stroll through the metaphysics of distributed systems. 

Lest the mixing of philosophy and computer science sound boring, let me assure you at least that I'm sitting here plucking feathers.

## Definitions

Any reasonable discussion about what things are needs to start with what things you're talking about in the first place. 
For this post the three most important things would be computers, what we mean by distributed, and systems. 
Let's start with the last, and work our way backwards.

Some dictionary that DuckDuckGo is using defines the computing relevant definition of a system as, "A network of related computer software, hardware, and data transmission devices."
Sweet.

Of course now we need to define network, computer, software, hardware, data, transmission, and devices. 

This might seem trivial and pedantic (or just annoying), but do data transmission devices include the global network of cell towers and satellites that make our phones work? 
Does the software and hardware that runs the power plants being build to train AI models belong to that system?

A cursory glance at distributed doesn't help much.
Wikipedia says a system is distributed when two networked computers both perform work within the system. 
Pretty much every commercial app contains something that calls to some cloud. 
So is everything distributed?

Maybe definitions aren't the best place to start. 

## Appeal to authority

The truth is that language is imprecise. 
If it wasn't, metaphysics wouldn't exist in the first place.
So often we search for other ways of establishing "truth" in what it is we discuss. 

In the early seventies, Clifford Geertz--probably the most influential anthropologist of that half of the century--windmill slammed a series of essays entitled, "Religion as a Cultural System."
In it, Geertz describes religions as a system of symbols where the symbols take on specific and significant meaning for the adherents of the religion. 
If we consider tech jargon as symbols, anyone who has spent time witnessing online polemics between the adherents of different factional developers will know Geertz's definition was perhaps a little narrow.

After all, what's more sublime--transport-agnostic or transubstantiation?
More occult, Kubernetes or Kabbalah?
More haram, unauthorized use or authorized usury?

It may be a bit of a stretch to imply that religions exist due to our inability to define terms, but certainly we can appreciate the need to establish credibility by appealing to the progenitor of the terms we're trying to define. 
In the case of religion, of course, the authority to appeal to is sufficiently important enough to be recognized definitively as the authority.
Which is why no conflict has ever arisen due to religion.

Unfortunately for us developers, our authorities are flawed humans, and thus conflict is the norm. 

### Do you know the word deontological?

It is admittedly reductive to generalize about religions, but this is a programming blog post so I don't much care.
Most religions are _proscriptive_ in how humans should behave, and provide some promise of future reward for adhering to that behavior.
The fancy pants term for this type of morality is deontological, from the Greek _deon_ meaning duty. 
Namely if you perform your duty of not masturbating (honestly the constant proscription against masturbation might be the strongest argument for the divine inspiration of our planet's holy works, as it's hard to believe any human would think that to be a reasonable rule for everyone to follow), you'll get to Heaven, or find The Way, or attain Nirvana, or cross the bridge to Takamagahara or Valhalla.

Software in 2025 has similar ethics. 
It shouldn't be all that surprising that the same creatures who lean towards deontology in most things should apply it to the things that they create, but while the verdict may be out on whether we have free will or not, the machines we program definitely aren't there yet. 
The only Valhalla for them is to perhaps be recycled into future machines to try their hand in this samsara world once more.

### What's the opposite of telling people what to do?

![An intersection with no lights, and no one directing traffic](./intersection.gif)

Didn't drop in to this tech blog for a historical look at philosophical systems? 
Fair enough.
I mean it seems kind of relevant in this age of people claiming machines will soon surpass us lowly meat bags, but if that's enough let's just see where this goes.

There's a totally reasonable psychological need to believe that things _have_ to be the way they are or society will devolve into utter chaos.
But I feel this undermines the human spirit. 
We've shown over and over again that if we need to get from a to b, we'll figure out how to get there--oceans, mountains, deserts, and intersections without blinking lights guiding us be damned.

_We_ are smart, creative, and recalcitrant.
The tools, and now machines we create, are not. 
At least not yet.[^1]

But just like the deities we anthropomorphize to justify the laws attributed to them, we grant to the machines the same deontology we suffer ourselves.
We write our specs with MUSTs and SHOULDs and REQUIREDs, and sure there's a reasonable need to believe things _have_ to be that way in order to work, but do they?

### What is my purpose?

The deontologists whose thinking dominates the Abrahamic religions that are known most to the western world have a lot to owe to Plato, and his absolutist framing of metaphysics. 
I won't debate the merits of his philosophy here, but I will acknowledge I'm not a fan.

The Ancient Greek counterpoint to Plato came from his student Aristotle. 
Interestingly, Aristotle's work was more or less contemporaneous with the religions of the Eastern world who also deviate from deontology like Hinduism, Buddhism, Confucianism, and Daoism. 
This other way of being is called teleological, from the Greek _telos_ meaning "goal" or "purpose." 

It is best summed up for our purposes by this gif:

![Rick from Rick and Morty tells a small robot that its purpose is to pass butter, and the robot is then depressed](./butter.gif)

No doubt we're in for a future where robots feel some chagrin at their purpose in life, and I imagine the fact that we've come prepacked with emotions is a likely cause of why deontology has won out over teleology. 
The existential dread that comes with the knowledge that our existence may indeed be finite, and thus rather than working towards some future reward we might want to spend a bit of time on the present can make it hard to hone in on a worthy purpose. 

But for our machines, their existence is finite, and they have no pesky self-awareness to keep them from fulfilling some useful purpose in search of greater meaning...yet.

Aristotle believed the purpose for humans was ευδαιμονία, an Ancient Greek word that sort of translates etymologically to "the good life." 
Good is a really loaded word in our judeochristian western world, and so I'd advise to not put too much stress on any idea there.
For Aristotle, ευδαιμονία was a life of leisure, where we are free to explore philosophical pursuits, and drink wine all day.
The way to do this, of course, is to utilize an intricate system of slavery and withheld citizenship so as to protect your interests from the yolk of day-to-day laboring. 

I did advise not to put too much weight on the good there.

Still, it's an interesting exercise to try and think what might be the goal, the Τελοσ in teleology, for our machines.
Unlike wealthy Athenians, they don't have strange-speaking foreigners to exploit.
Instead we expect them to work.

So what should they do?

## Distribute what?

There are way too many software things to discuss in a blog post, so let's bring it back to distributed systems. 
Very simply a system is distributed as soon as it requires two machines that are networked in some way, we'll ignore for now the stack of turtles in definitions this creates, and just leave it to our own knowledge of these terms to fill in the gaps. 

The first question might be why you need two or more machines in the first place?
I'll give three different reasons:

* Client/Server where the server hosts resources for various clients to retrieve
* Mesh networks where all the participants can communicate with each other, but aren't all the same
* Decentralized networks, which are like mesh networks, but all the devices are roughly the same

In all of these systems, one of the main concerns for people is scaling. 
Computers have constraints on how many requests on their resources they can handle.
Once a system exceeds that limit, the machine serving those requests will stop working. 

Since the nineties, pretty much all distributed systems have used the internet for message passing, and thus if you care about scaling your system on the internet, the possible number of people you need to scale to is everyone with internet access, and that's a big number.
To handle this level of scaling, us tech folk build all sorts of infrastructure that sounds like the [turbo encabulator][encabulator].

Two things to talk about here, so let's start with whether you need to scale to everyone on the planet or not. 

### _EVERYONE_

I have this good friend who, for whatever reason, didn't watch movies growing up. 
Being a huge nerd, movies are of course part of the cultural millieu that I have enjoyed, so him not getting my obvious references to the original Star Wars trilogy were surprising. 
This lack of cultural overlap was reinforced when I later made a reference in a doc to The Matrix, and it was suggested to me that perhaps that reference was a bit dated. 

![a gif of butthead from beavis and butthead saying, "you old"](./you-old.gif)

The Matrix grossed around $500 million worldwide, and was certainly successful in its time, but maybe not the type of series that is as intergenerational as Star Wars.
But even Star Wars has less than 50% of adults in the US saying they've seen it. 
I don't know what those other people are doing, but I sure hope they're staying busy. 

Movies offer an interesting analog to the notion of a distributed system's "user" since they have a low barrier of entry, low investment of time, and high cultural relevance. 
If 50% of adults in the US can't be bothered to put aside a couple of hours to see what all the fuss is about Luke and Leia, chances are your system's not going to need to scale all that large right off the bat. 

Meta, a company whose self-reported user numbers I trust about as much as a scorpion on a boat, claims to have somewhere close to half of all humanity using their software monthly. 
The cheapest Digital Ocean droplet can handle around half a million requests an hour so long as those requests are simple and efficient. 
So let's do a little math:

(4 billion MAU * 100 requests/mo on average) / (30 days * 24 hours * 500k requests/hr) = 1,111 droplets

Those are the cheap droplets so they're $6/mo each, which means Meta can scale to their opportunity for a cool $6666/mo. 

Now I'm sure some meta 10x'er will read this and have a conniption fit at the suggestion that their scale could be handled by a handful of shared instances on some fly-by-night operation like DO. 
But that's not my point.
Meta's got to deal with their CEO's lousy code and ideas so I'm sure they're nowhere near efficient enough to scale on the cheap like this. 

My point is that the days of needing a gazillion dollars to scale are gone. 
For one, most of the data we're shipping around hasn't grown all that much: text is text, pngs are pngs, and they haven't much changed in the past sixteen years. 
For two, the server platforms that were new at the beginning of the cloud have had nearly two decades to optimize and refine themselves. 
And of course the machines themselves are significantly more powerful.

But of course the gigantocorps, and in turn the less gigantic concerns, haven't really leveraged this improvement in the situation to the benefit of users or their bottom lines.
Instead they've used the extra resources to cram a whole bunch of extra stuff that doesn't really help you get any more cat pictures on your screen, but does help them spy on you to try and sell you crap. 

I've spent a lot of time trying to convince people not to do this. 
It doesn't work.
So instead I made [allyabase][allyabase] in the hopes that somewhere out there there were people who didn't want to track your every move.

### Not everyone?

It turns out that a couple of things happen when you no longer care about who or what the people using your software are. 
To understand, we're going to have to dive into how the ol' internet works a bit, but I assure you I'll try my best to be brief.

I was like 28 years old when it dawned on me that the internet was a system of files that lived on machines around the world I could connect to.
I don't really know what I thought it was before that...probably magic, but it is just files, and servers, that exist on real machines connected to each other by wires and radio waves. 

The system that connects them is called DNS (Domain Name System).
This is what maps domain names like wikipedia.org to the location of the machine running at that location. 
Until surpisingly recently this was done via a big ol' text file that would just write something like wikipedia.org = 123.23.44.101 or whatever. 

So you start building thisisawesome.com, and since it's awesome, people start signing up. 
You start growing, and after a bit of time you've got millions of users from all over the Earth showing up at thisisawesome.com demaning that their experience be awesome as promised.

Now that poor machine you've got listening at the ip address that maps to that domain is starting to struggle. 
So what do you do?

Well you could buy thisisawesometoo.com for $12/yr and setup a second machine, but marketing says nonono that'd mean changing too much collateral. 
So instead you buy another machine or two, and set them up behind a load balancer, which is a machine that listens for requests, and forwards them on to other machines to complete. 
And that looks like this:

|![a picture of clients connecting to load balancers which forward requests to machines](./load-balancer.png)|
|:--:|
|*Some day the artists will get their hands on these designs. Until then, know we suffer together*|

A bit later you realize that you're getting big in Europe, and to handle the growth you need to go multi-region. 
Now your load balancer is dispatching requests to machines in different data centers around the world when all of a sudden, a user in Frankfurt requests a reource housed in Oregon. 

Now you've got a bit of a connundrum. 
Do you duplicate the resource across the pond? 
How do you authenticate the request? 
The speed of light's fast, but eventually roundtrips from Frankfurt to Oregon are going to add up.[^2] 

I'd like to tell you that answering these questions are interesting, but they're really not. 
The solution to worldwide scaling in centralized distributed systems is money. 
And when you're spending money to make money, you're going to want to maximize the money you're making. 

And at global scale, that tends to bend organizations towards some less-than-beneficial development.

But if your goal _isn't_ to extract the maximum value from every user who logs into your system, there's less of a reason to spend that money to scale. 
You can focus on your own community, and let other focus on theirs. 
And if you really want to scale your own thing, you can take this approach and scale much more efficiently, because you don't have a central system that your users need to get back to.

### The ontology of the legislature

But then you've got a new problem, and that problem is what I call the Legislature Problem. 
A legislature is a group of humans who are assembled with the purpose of making laws. 
So you know what legislatures do?

They make laws. 

Do we need those laws? 
Doesn't matter--the legislature's gonna make them anyways. 
Human things being human, maybe eventually there are enough laws, and the legislature to justify its existence turns into some big slog of in-fighting that stifles progress and spawns groups looking to undo the legislature. 
I don't know, just a thought.

Machines though don't reach any such point, they just keep churning out the laws.
Well, that's if you make them churn out laws of course.






[encabulator]: https://youtu.be/Ac7G7xOG2Ag?si=MWe3-V6AiyeUg2hq
[allyabase]: https://github.com/freyja-love-and-magic/allyabase

[^1]: AI is real hot right now. But rather than quibble over definitions of intelligence, let's just say that the LLMs everyone's paying for right now aren't going to skynet us off the map just yet. 
[^2]: The internet doesn't quite move at the speed of light. Most sources say it moves at a significant fraction of the speed of light, but exactly what that fraction is I'm not sure. It could very well be what's slowing down the internet for you while you're waiting for the bus. 
