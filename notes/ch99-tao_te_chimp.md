# Appendix A: Tao Te Chimp

What follows are the points of our way as a set of *decision criteria* -- points of practice whose common sense and precise statement are agreed to in a period of calm, so they may be deployed in a period of action.

For us, the granddaddy of them all is "Don't solve problems you'd like to have". Considering a system to pay comissions automatically? Don't! What a joyful problem it will be, to have so much pass-through revenue that writing checks to suppliers becomes a burden. That decision criterion and the others below have struck a swift and happy end to countless meetings, foofaraws, imbroglios and debates.

Decision criteria should be

* **Pithy and Precise**. They're meant to resolve discussions, not to spur recursion into a second-level debate about their own merits. State them briefly and the same way every time.
* **Audacious**. Planting your stake at the farthest reach makes it hardest to budge, and forces simplicity. [Stopping the entire assembly line on every flaw](http://www.toyota-global.com/company/toyota_traditions/quality/jul_aug_2004.html) seems enormously disruptive. *Good*. That disruption exposes the brutal truth about your defect rate, leaves the entire team highly motivated to cure it, and gives you scope to examine the defect within the context of the whole system.  Apparent exceptions to an extreme rule typically stem from deeper process flaws. 
* **Assertive**. Decision criteria stand universally and without reservations or exceptions. To be clear: multiple criteria may conflict, and criteria may lose to a host of well-reasoned countervailing factors. But the simple standard is "a plan that has this feature is better than a plan that does not"

## Points of the Tao

This is our creed:

* Be effective, 
* be a good teammate,
* build something amazing,
* to make the world better by making the world smarter.

This is our way:

### Be Effective

**Squirrel sí, Pony no**

* Don't solve problems you'd like to have
* Meetings are the death of productivity
* Overlay beats refactor; NEVER rewrite
* Just Ship: Beautiful code is code that is in production
* There is no "easy": weigh COSMIQ (Cost of Operations, Support, Marketing, Infrastructure, QA)
* Look for the point where one acceptable plan is better than two great plans
* Life, sometimes, is Russian novel - but novel, is not by Dostoyevsky
* A week should never pass without doing some work you look forward to doing
* Weigh a plan that is more conservative and a plan that is more aggressive
* When in doubt of a plan, solicit the opinion of its most likely nemesis

### Be a Good Teammate

**Obligation to Consensus, Obligation to Dissent**

* Mistakes born of bold initiative in service of the plan are always forgivable, mistakes born of timidity or indecision are never acceptable
* Where multiple consensus is required, use a star topology - synthesize opinions, identify dissent and only then call a meeting
* Favor aptitude over experience, and passion above all
* We have a collective commitment to, and expectation of, extraordinary career growth
* Internal Ops drink for free
* Pooflinger rule: When a problem happens, look at process, team, and people in that order of importance
* Hold the org chart upside-down: your manager works for you

### Build Something Amazing 

**Powerful black boxes, Beautiful Glue**

* Write your code for humans to read, not for computers to execute
* The most direct and accurate way to optimize for process is to optimize for joy
* The more you decouple the better you scale
* Airplane Laptop rule: repos must run in nearly complete isolation
* Automate out of boredom or terror never efficiency
* Good tests make good neighbors and confident deploys, but be sure you're not trying to outhink the real world
* If nobody has built it for you to steal, why do you think you need it?
* Debug loop time is our most precious currency
* Critical path lines of code are our most costly debt

### Make the world Better by making the world Smarter

**A startup is a device for turning time and money into validated assumptions about what the world wants**

* Generate more value than you consume
* Engineering's job is to say yes, sales/product's job is to say no
* Hiring is always a top priority for the whole team
* Make decisions for the company of now, not the different one it will be in three months
* process must always be for the benefit of, and embraced by, those who have to follow it
* Beware the Ides of team size 12, 50, and 144 - watch for the inflection points in human scaling factors (at 12 and 144) or strength of culture (at 50) that can destroy your organization
* Build your team according to a scalable architecture


## Sources

* Algeri Wong's [rules for Engineering Management](http://algeri-wong.com/yishan/engineering-management.html)
* The [Toyota Way](http://www.toyota-global.com/company/toyota_traditions/quality/) and [The Machine that Changed the World](http://www.amazon.com/Machine-That-Changed-World-Revolutionizing/dp/0743299795)
* [The Marine Corps Way](http://books.google.com/books?id=qyTfKq12SbMC)
* [Rands in Repose](http://www.randsinrepose.com/)
* John Allspaw, Kellan Elliott-McCrea and the rest of the Flickr-Etsy mafia. "Just Ship", our essential focus on culture, optimizing for joy, and more were learned from them.


## Points of the Tao, explained

### Be Effective

**Squirrel sí, Pony no**


#### Don't solve problems you'd like to have


* "let users change their username" -- you should be so lucky as to have so many users you can't do this manually any more
* "automated payment of comissions" -- what an amazing problem, to find you have so much revenue the outgoing comissions have become a burden.

Note well its corollary: **Don't even fuck with a problem you wouldn't possibly know how to solve**.

See also: "Automate out of Boredom or Terror, never Efficiency" and "Make decisions for the company of now, not the different one it will be in three months"


#### Meetings are the death of productivity

...


#### Sometimes refactor, rarely rebuild, NEVER rewrite

Overlay new functionality, leaving the old code running in production. Once the bulk of its functionality has been replaced and its subtle lessons harvested it's a fairly easy to transition (or better yet kill) its remaining features.


#### Just Ship: Beautiful code is code that is in production

...


#### There is no "easy": weigh COSMIQ (Cost of Operations, Support, Marketing, Infrastructure, QA)

...


#### Look for the point where one acceptable plan is better than two great plans

...


#### Life, sometimes, is Russian novel. But novel, is not always by Dostoyevsky


    Life, sometimes, is Russian Novel. Is having unhappy marriage and much snow and little vodka.
    But when the Russian Novel it is short, then quickly we finish and again read Sweet Valley High.

...


#### A week should never pass without doing some work you look forward to doing

...


#### Weigh a plan that is more conservative and a plan that is more aggressive

...


#### Be able to fully and passionately advocate all the arguments *against* your plan

#### When in doubt of a plan, solicit the opinion of its most likely nemesis


If I am leaning towards a plan that costs more money over one that's cheaper, I take it to our COO 
If I am leaning towards something that's risky, I can take it to our Sr Ops Engineer, Nathan. He can, often in one or two sentences, point out the utter naked foolishness of a reckless plan. But if Nathan becomes convinced the risks are unavoidable or outweighed by the benefits, it's likely a solid plan

There's t
* Closing the consensus loop is a snap; in fact the fastest route can be to have the natural nemesis explain the plan
* You leave able to clearly articulate the case against your plan (see above)
* You're often talking to the person who will most heavily experience its downside

And if I think a plan is too expensive, too risky, or can't be built in an improbably short period of time, then you should look very carefully at that plan again.

### Be a Good Teammate

**Obligation to Consensus, Obligation to Dissent**

#### Mistakes born of bold initiative in service of the plan are always forgivable, mistakes born of timidity or indecision are never acceptable

This is a principle restated from [The Marine Corps Way](http://books.google.com/books?id=qyTfKq12SbMC).


#### Where multiple consensus is required, use a star topology - synthesize opinions, identify dissent and only then call a meeting

...


#### Favor aptitude over experience, and passion above all

...


#### We have a collective commitment to, and expectation of, extraordinary career growth

...


#### Internal Ops drink for free

The key activity of your internal ops team -- from the folks who file the health insurance bills to the folks who answer the 3am pager when a server goes down -- is to make problems go away or (if they're as good as ours is) never be.

This leads to the danger that you'll either only think of them in times of crisis or not at all.

The 'internal ops drink for free' rule 

#### Pooflinger rule: When a problem happens, look at process, team, and people in that order of importance

...


#### Hold the org chart upside-down: your manager works for you

...



### Build Something Amazing 

**Powerful black boxes, Beautiful Glue**

#### Write your code for humans to read, not for computers to execute

...

#### We DO NOT solve hard problems -- we take hard problems and turn them into easy ones.

Stole this one from Pete Skomoroch.

See also: [If nobody has built it for you to steal, why do you think you need it?]


#### The most direct and accurate way to optimize for process is to optimize for joy

...

The central challenge of engineering is when to invest a week of work now to gain an unknowable amount of value and saved work later. 

We cost engineering decisions according to engineer weeks and engineer centiBallmers. The Ballmer is the metric unit of programmer pain, defined as the amount of pain spent optimizing a website's CSS to work on Internet Explorer 6.

#### The more you decouple the better you scale

...


#### Airplane Laptop rule: repos must run in nearly complete isolation

This is 


#### Automate out of boredom or terror, never efficiency

...


the Toyota Production System sets not automation but [Autonomation (Jidoka)](http://en.wikipedia.org/wiki/Autonomation) -- "automation with a human touch".

#### Good tests make good neighbors and confident deploys, but be sure you're not trying to outhink the real world

...


#### If nobody has built it for you to steal, why do you think you need it?

...


#### Debug loop time is our most precious currency

...


#### Critical path lines of code are our most costly debt

...

#### Kill a feature ... and if people complain, *make that feature AWESOME*.

Code is debt.


## Make the world Better by making the world Smarter

**A startup is a device for turning time and money into validated assumptions about what the world wants**

#### Generate more value than you consume

...


#### Engineering's job is to say yes, sales/product's job is to say no

Saying "Engineering's job is to say yes, Sales and Product's job is to say no" means as an engineer I have to stop and say "Wait, have I done everything I can to think like the customer, or to try to deliver filet mignon at a Chicken McNugget price?" -- and as a salespersion I have to ask
"This feature is nice, but is it nicer than all the other nice features that would be nice to have?"

The corollary is that Engineering's job is to help product say no: for them to understand what can be built, how much it will cost, and that by saying yes to this project you're saying no to all the other ones we could be building instead. Product and Sales' job is to help engineering say yes: to make sure they understand *why* the customer needs this thing (and thus can design accordingly), to use 

#### Hiring is always a top priority for the whole team

...


#### Make decisions for the company of now, not the different one it will be in three months

Your startup will be out of business in three months: replaced by a different company, one of a different size (larger, smaller, perhaps extinct), different and clearer business hypotheses, different team composition, different extent of customer education.

Does it make sense to automate a process that runs once a month, given that this means your current company will only execute it three times? Your next company might not need it or might have people better suited to build it. See [Automate out of Boredom or Terror, never Efficiency] for more.


#### process must always be for the benefit of, and embraced by, those who have to follow it


If a test-driven development workflow doesn't have you writing code and tests *faster* than you would writing the code alone, you're doing it wrong.

If your manager is asking you to prepare what feel like TPS reports, 
obligation to dissent says [pull the line stop cord](http://www.youtube.com/watch?v=B_nSvN_L4hc) *now*.

Are you and your manager [holding the org chart upside down]? Your manager works for you: her job is to get things out of your way, so you can build something amazing. Make sure you're managing up (leave her in no doubt that this is getting in your way) and that you understand why it's in place. Can you find a way to meet the goals of the process in a way that speeds you up, not slows you down?


#### Beware the Ides of team size 12, 50, 144 - the first and the last are human scaling factors, the middle is your culture inflection point

...


#### Build your team according to a scalable architecture

...


# Notes



Here are some of the most important sources:

* If you haven't read Algeri Wong's [rules for Engineering Management](http://algeri-wong.com/yishan/engineering-management.html) bookmark this and go read that instead. Every one of them has been adopted into the Tao Te Chimp in some form.
* The [Toyota Way](http://www.toyota-global.com/company/toyota_traditions/quality/) and [The Machine that Changed the World](http://www.amazon.com/Machine-That-Changed-World-Revolutionizing/dp/0743299795)
* [The Marine Corps Way](http://books.google.com/books?id=qyTfKq12SbMC)
* Rands (aka Michael Lopp) applies engineering principles to the management of engineers; read more in his superb [blog](http://www.randsinrepose.com/) and the  [book](http://www.amazon.com/Managing-Humans-Humorous-Software-Engineering/dp/159059844X) it led to.
* John Allspaw, Kellan Elliott-McCrea and the rest of the Flickr-Etsy mafia. "Just Ship", our essential focus on culture, optimizing for joy, and more were learned from them.

Note: I said 'apply', not 'win'. They are not always right, should not always carry the day, and a majority of criteria in favor of A over B does not immediately decide in favor of A  (sometimes the result of a vote is "unanimously in favor, 1 for and 3 against").

Every one of them is right, in the sense that "A plan that meets this criterion is better than a plan that does not". But that doesn't mean any one or several should carry the day. In fact, some of the rules below are purposefully contrapuntal -- to others (eg the [airplane laptop] rule vs the [decouple] rule) or themselves (eg [Obligation to consensus, Obligation to dissent])

Many of them are purposefully stated to turn your thinking upside-down. 
Saying "Engineering's job is to say yes, Sales and Product's job is to say no" means as an engineer I have to stop and say "Wait, have I done everything I can to think like the customer, or to try to deliver filet mignon at a Chicken McNugget price?"

Some of these are original, reflecting our approach to scalable nimble architecture of teams and systems. Many are synthesized from what we've read or been taught. And as great artists do, many are stolen outright (see "If you can't steal it, do you *really* think you need it"). 



Our management philosophy is our engineering philosophy:
take the rules for building scalable nimble architectures and use them to build a scalable nimble team; take the rules for iterating towards a scalable repeatable business model
and use them to guide engineering thinking.
