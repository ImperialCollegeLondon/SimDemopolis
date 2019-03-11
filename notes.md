# Final Year Project Notes

## Network Characteristics to Measure
- Centrality
- How the network breaks down into _communities_.
- Inequality of "work" done by each agent, as measured by the Gini Index


## TODO
- Have a look to see what exactly the _Gini Index_ is.
- Have a look at how best to write a really good literature survey
- Re-read _Demopolis_, and make sure I've covered all the main points 
in the report
- Read _Democracy and Knowledge_ (preferably quite quickly)
- Read all of _Networks - an introduction_
- Read some more of the other Network Science book
- Read the Prolog book
- Do the prolog exercises I never did last term
- Examine _SimDemoplis in thourough detail, and annotate what exatly every bit of it does
- See if there is a way of modularizing the code (in a similar way one would do with object-oriented code)

### Interim Report
- Finish the introduction
- Write the stuff on random networks
- Write the stuff on scale-free networks
- Write the stuff on small-world networks
- Get the bibliography working

## Done
- Read the relevant parts of Demopolis

## General Notes
- The Small-World effect is very common in real-world social networks (the 
so-called _Six Degrees of Separation_ effect).
- Is this project more concerned with _social_ networks or _information_ networks
- Will an existing network topology model have to be constructed? Will simply 
- Expand on the Delegation Game of Ober p133. What else must be done in this regard.
re-creating Demopolis in a different programming language be a better idea?
  - To Study this, have a look at how Demopolis
- The experiments originally conducted on _Demopolis_ investigated 
  1. A baseline test for equal sharing of roles
  2. Detection of "power grabs" and "free riding
  3. Bias detection in the role assignment protocol
  
## SimDemopolis
- The ^^ operator means "points to"
- SimDemopolis implements the "delegation game" shown in _Demopolis_, p133

## Network Structure
- Network is a random graph G = <A,p>, where A is the set of agents, and p is the probability of a link between any two members of A.

### Small-World Network (Watts-Strogatz Model)
- Problem - Needs to start with a ring network and then randomly re-arrange itself. How to implement this 2-stage process in Prolog?

## General Implementation Notes
- When reading stuff, take notes. It may slow reading down significantly, 
but reduces the need to go back and re-read stuff later
- While I'm going along, and after O