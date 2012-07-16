
### How to choose keys

/best practices/
* Truth flows from the edge inward
* Keep your data flows recapitulateable - This ensures confidence in provenance, is enormously helpful for debugging and validation, and is a sign you're thinking correctly
* Data size is cheaper than you think. Compression is cheaper and much better than you'd think.
TODO: collect the best practices back at "How to think"

Wherever possible, use intrinsic metadata to assign identifiers. 

This means you can assign identity at the edge. An auto increment field requires locality - something has to keep track of the counter; or you'd need to do a total sort.

You can use the task id as prefix or suffix and number lines.

When I was born, my identity was assigned at the edge: Philip Frederick Kromer IV. This identifier has three data elements that serve to scope my record, and a disambiguating index. It's not a synthetic index, though -- Philip Frederick Kromer III (my dad) was uniquely involved in supplying the basis for the auto increment field.

People coming from the SQL world find this barbaric, and a hard habit to break. remember: data and compression are cheap, locality is expensive. If you're worried about it, sort on the SHA-HMAC of your identifying fields, number as if the auto increment fairy brought it